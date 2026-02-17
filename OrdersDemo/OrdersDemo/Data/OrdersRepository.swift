import Combine
import Foundation

public protocol OrdersRepository: Sendable {
    /// Fetches a page of orders. Pass `cursor: nil` for the first page; pass the returned `nextCursor` for subsequent pages. Returns empty orders and nil cursor when no more data.
    func fetchOrders(cursor: String?, limit: Int) async throws -> OrdersPage
    /// Type-erased publisher of status updates for the given order. Callers depend only on `AnyPublisher`, not the concrete publisher.
    func statusUpdates(for orderID: UUID) -> AnyPublisher<OrderStatus, Never>
    /// Emits (orderID, status) whenever any order’s status changes. List can subscribe to update UI without reloading.
    func orderStatusUpdates() -> AnyPublisher<(orderID: UUID, status: OrderStatus), Never>
}

public extension OrdersRepository {
    func orderStatusUpdates() -> AnyPublisher<(orderID: UUID, status: OrderStatus), Never> {
        Empty(completeImmediately: false).eraseToAnyPublisher()
    }
}

