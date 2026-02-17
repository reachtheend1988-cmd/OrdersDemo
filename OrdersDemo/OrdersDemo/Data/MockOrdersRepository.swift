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

public actor MockOrdersRepository: OrdersRepository {
    private let requestDelay: RequestDelay

    private var orders: [Order]
    private let fetchBehavior: OrdersFetchBehavior

    private let statusUpdateIntervalSeconds: TimeInterval
    private let statusSequences: [UUID: [OrderStatus]]

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
            return OrdersPage(orders: page, nextCursor: nextCursor)
        case .empty(let delaySeconds):
            await requestDelay.sleep(seconds: delaySeconds)
            return OrdersPage(orders: [], nextCursor: nil)
        case .failure(let delaySeconds):
            await requestDelay.sleep(seconds: delaySeconds)
            throw MockOrdersError.simulatedFailure
        }
    }

    /// Returns a type-erased publisher that emits status updates. Implementation uses a subject and a background task so callers only see `AnyPublisher<OrderStatus, Never>`.
    public nonisolated func statusUpdates(for orderID: UUID) -> AnyPublisher<OrderStatus, Never> {
        let subject = PassthroughSubject<OrderStatus, Never>()
        Task { [weak self] in
            guard let self else {
                subject.send(completion: .finished)
                return
            }
            let (sequence, interval) = await self.sequenceAndInterval(for: orderID)
            for status in sequence {
                await self.requestDelay.sleep(seconds: interval)
                subject.send(status)
            }
            subject.send(completion: .finished)
        }
        return subject.eraseToAnyPublisher()
    }

    private func sequenceAndInterval(for orderID: UUID) -> ([OrderStatus], TimeInterval) {
        (statusSequences[orderID] ?? [], statusUpdateIntervalSeconds)
    }
}

public extension MockOrdersRepository {
    static func demo(
        bundle: Bundle = .main,
        requestDelay: RequestDelay = .taskSleep
    ) -> MockOrdersRepository {
        let orders = Self.loadDemoOrders(from: bundle)

        let sequences: [UUID: [OrderStatus]] = {
            guard orders.count >= 2 else { return [:] }
            return [
                orders[0].id: [.inTransit, .delivered],
                orders[1].id: [.delivered]
            ]
        }()

        return MockOrdersRepository(
            orders: orders,
            fetchBehavior: .success(delaySeconds: 1.0),
            statusSequences: sequences,
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

