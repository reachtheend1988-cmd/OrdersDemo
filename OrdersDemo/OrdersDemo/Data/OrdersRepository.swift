import Combine
import Foundation

public protocol OrdersRepository: Sendable {
    /// Fetches a page of orders. Pass `cursor: nil` for the first page; pass the returned `nextCursor` for subsequent pages. Returns empty orders and nil cursor when no more data.
    func fetchOrders(cursor: String?, limit: Int) async throws -> OrdersPage
    /// Type-erased publisher of status updates for the given order. Callers depend only on `AnyPublisher`, not the concrete publisher.
    func statusUpdates(for orderID: UUID) -> AnyPublisher<OrderStatus, Never>
}

