import Combine
import Foundation

@MainActor
public final class OrderListViewModel: ObservableObject {
    private static let pageSize = 10

    @Published public private(set) var state: LoadState<[Order]> = .idle
    @Published public var filter: OrderStatusFilter = .all
    @Published public private(set) var nextCursor: String?
    @Published public private(set) var isLoadingMore = false

    private let ordersRepository: OrdersRepository
    private var loadTask: Task<Void, Never>?
    private var loadMoreTask: Task<Void, Never>?
    private var orderStatusCancellable: AnyCancellable?

    public init(ordersRepository: OrdersRepository) {
        self.ordersRepository = ordersRepository
        self.orderStatusCancellable = ordersRepository.orderStatusUpdates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] orderID, status in
                self?.applyOrderStatusUpdate(orderID: orderID, status: status)
            }
    }

    private func applyOrderStatusUpdate(orderID: UUID, status: OrderStatus) {
        guard case .loaded(var orders) = state else { return }
        guard let index = orders.firstIndex(where: { $0.id == orderID }) else { return }
        var order = orders[index]
        order.status = status
        orders[index] = order
        state = .loaded(orders)
    }

    public func onAppear() {
        // Only load once automatically. After that, keep the loaded list updated via `orderStatusUpdates()`.
        // Refetching (cursor/nil) should only happen when the user explicitly taps "Reload".
        guard case .idle = state else { return }
        reload()
    }

    public func reload() {
        loadTask?.cancel()
        loadMoreTask?.cancel()
        state = .loading
        nextCursor = nil

        loadTask = Task { [ordersRepository] in
            do {
                let page = try await ordersRepository.fetchOrders(cursor: nil, limit: Self.pageSize)
                guard !Task.isCancelled else { return }

                if page.orders.isEmpty {
                    self.state = .empty
                } else {
                    self.state = .loaded(page.orders)
                    self.nextCursor = page.nextCursor
                }
            } catch {
                guard !Task.isCancelled else { return }
                self.state = .failed(
                    ErrorDisplay(
                        title: "Couldn't load orders",
                        message: "Please check your connection and try again."
                    )
                )
            }
        }
    }

    /// Loads the next page using the current cursor. No-op if there is no cursor or a load is already in progress.
    public func loadMoreIfNeeded() {
        guard nextCursor != nil, !isLoadingMore, case .loaded = state else { return }
        loadMoreTask?.cancel()

        loadMoreTask = Task { [ordersRepository] in
            let cursor = self.nextCursor
            guard let cursor else { return }
            self.isLoadingMore = true
            defer { self.isLoadingMore = false }
            do {
                let page = try await ordersRepository.fetchOrders(cursor: cursor, limit: Self.pageSize)
                guard !Task.isCancelled else { return }
                if case .loaded(let current) = self.state {
                    self.state = .loaded(current + page.orders)
                    self.nextCursor = page.nextCursor
                }
            } catch {
                guard !Task.isCancelled else { return }
                self.nextCursor = nil
            }
        }
    }

    public var filteredOrders: [Order] {
        guard case .loaded(let orders) = state else { return [] }
        guard let status = filter.status else { return orders }
        return orders.filter { $0.status == status }
    }

    /// The id of the last order in the full loaded list (before filtering). Use this to trigger load more only when the user scrolls to the end of loaded data, not when the filter changes.
    public var lastLoadedOrderId: UUID? {
        guard case .loaded(let orders) = state, let last = orders.last else { return nil }
        return last.id
    }

    public var hasMorePages: Bool { nextCursor != nil }
}
