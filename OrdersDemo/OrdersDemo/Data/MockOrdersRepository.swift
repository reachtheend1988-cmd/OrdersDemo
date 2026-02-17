import Combine
import Foundation

public enum MockOrdersError: Error, Equatable, Sendable {
    case simulatedFailure
}

public enum OrdersFetchBehavior: Equatable, Sendable {
    case success(delaySeconds: TimeInterval)
    case empty(delaySeconds: TimeInterval)
    case failure(delaySeconds: TimeInterval)
}

/// Thread-safe mock repository.
/// - Uses a private serial queue for state (`orders`, `statusSequences`)
/// - Uses Combine publishers for updates (no actor isolation, no `nonisolated(unsafe)`)
public final class MockOrdersRepository: OrdersRepository {
    private let requestDelay: RequestDelay

    private let fetchBehavior: OrdersFetchBehavior

    private let statusUpdateIntervalSeconds: TimeInterval
    private let stateQueue = DispatchQueue(label: "MockOrdersRepository.state")
    private var orders: [Order]
    private var statusSequences: [UUID: [OrderStatus]]

    /// Emits whenever any order’s status changes so the list can update without reloading.
    private let orderStatusUpdateSubject = PassthroughSubject<(orderID: UUID, status: OrderStatus), Never>()

    public init(
        orders: [Order],
        fetchBehavior: OrdersFetchBehavior,
        statusSequences: [UUID: [OrderStatus]],
        statusUpdateIntervalSeconds: TimeInterval = 2,
        requestDelay: RequestDelay = .taskSleep
    ) {
        self.orders = orders
        self.fetchBehavior = fetchBehavior
        self.statusSequences = statusSequences
        self.statusUpdateIntervalSeconds = statusUpdateIntervalSeconds
        self.requestDelay = requestDelay
    }

    public func fetchOrders(cursor: String?, limit: Int) async throws -> OrdersPage {
        switch fetchBehavior {
        case .success(let delaySeconds):
            await requestDelay.sleep(seconds: delaySeconds)
            return stateQueue.sync {
                let sorted = orders.sorted { $0.createdAt > $1.createdAt }
                let startIndex: Int
                if let cursor, let cursorUUID = UUID(uuidString: cursor), let idx = sorted.firstIndex(where: { $0.id == cursorUUID }) {
                    startIndex = idx + 1
                } else {
                    startIndex = 0
                }
                let endIndex = min(startIndex + limit, sorted.count)
                guard startIndex < sorted.count else {
                    return OrdersPage(orders: [], nextCursor: nil)
                }
                let page = Array(sorted[startIndex..<endIndex])
                let nextCursor = endIndex < sorted.count ? page.last?.id.uuidString : nil

                // Update sequences for any orders we just returned.
                let newSequences = buildStatusSequencesForPage(page)
                for (id, seq) in newSequences {
                    statusSequences[id] = seq
                }

                return OrdersPage(orders: page, nextCursor: nextCursor)
            }
        case .empty(let delaySeconds):
            await requestDelay.sleep(seconds: delaySeconds)
            return OrdersPage(orders: [], nextCursor: nil)
        case .failure(let delaySeconds):
            await requestDelay.sleep(seconds: delaySeconds)
            throw MockOrdersError.simulatedFailure
        }
    }

    /// Builds status sequences for every order in the page so statusUpdates(for:) always has a sequence when the user opens details for any listed order.
    private func buildStatusSequencesForPage(_ page: [Order]) -> [UUID: [OrderStatus]] {
        guard !page.isEmpty else { return [:] }
        var result: [UUID: [OrderStatus]] = [:]
        for (index, order) in page.enumerated() {
            switch index {
            case 0: result[order.id] = [.inTransit, .delivered]
            case 1: result[order.id] = [.delivered]
            default: result[order.id] = [.delivered]
            }
        }
        return result
    }

    private func sequenceAndInterval(for orderID: UUID) -> ([OrderStatus], TimeInterval) {
        stateQueue.sync { (statusSequences[orderID] ?? [], statusUpdateIntervalSeconds) }
    }

    private func applyStatusUpdate(orderID: UUID, status: OrderStatus) {
        var didUpdate = false
        stateQueue.sync {
            guard let index = orders.firstIndex(where: { $0.id == orderID }) else { return }
            orders[index].status = status
            didUpdate = true
        }
        if didUpdate {
            orderStatusUpdateSubject.send((orderID: orderID, status: status))
        }
    }

    /// Emits status updates from statusSequences for this order (set when fetchOrders succeeds). Each subscription gets the current sequence; in-memory orders are updated so the list stays in sync. If the list hasn't finished loading yet, waits briefly and retries once so opening details quickly still gets updates.
    public func statusUpdates(for orderID: UUID) -> AnyPublisher<OrderStatus, Never> {
        let subject = PassthroughSubject<OrderStatus, Never>()
        Task { [weak self] in
            guard let self else {
                subject.send(completion: .finished)
                return
            }
            var (sequence, interval) = self.sequenceAndInterval(for: orderID)
            if sequence.isEmpty {
                await self.requestDelay.sleep(seconds: 0.5)
                (sequence, interval) = self.sequenceAndInterval(for: orderID)
            }
            for status in sequence {
                await self.requestDelay.sleep(seconds: interval)
                self.applyStatusUpdate(orderID: orderID, status: status)
                subject.send(status)
            }
            subject.send(completion: .finished)
        }
        return subject.eraseToAnyPublisher()
    }

    public func orderStatusUpdates() -> AnyPublisher<(orderID: UUID, status: OrderStatus), Never> {
        orderStatusUpdateSubject.eraseToAnyPublisher()
    }
}

public extension MockOrdersRepository {
    static func demo(
        bundle: Bundle = .main,
        requestDelay: RequestDelay = .taskSleep
    ) -> MockOrdersRepository {
        let orders = Self.loadDemoOrders(from: bundle)

        return MockOrdersRepository(
            orders: orders,
            fetchBehavior: .success(delaySeconds: 1.0),
            statusSequences: [:],
            statusUpdateIntervalSeconds: 2.0,
            requestDelay: requestDelay
        )
    }

    /// Loads demo orders from `orders.json` in the given bundle. Returns an empty array if the file is missing or invalid.
    static func loadDemoOrders(from bundle: Bundle) -> [Order] {
        guard let url = bundle.url(forResource: "orders", withExtension: "json", subdirectory: nil) else {
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([Order].self, from: data)
        } catch {
            return []
        }
    }
}

