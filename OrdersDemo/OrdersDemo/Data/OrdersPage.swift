import Foundation

/// A page of orders returned from a cursor-based fetch. `nextCursor` is nil when there are no more pages.
public struct OrdersPage: Sendable {
    public let orders: [Order]
    public let nextCursor: String?

    public init(orders: [Order], nextCursor: String?) {
        self.orders = orders
        self.nextCursor = nextCursor
    }
}
