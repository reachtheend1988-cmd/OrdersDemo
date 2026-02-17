import Foundation

public struct AppEnvironment: Sendable {
    public var ordersRepository: OrdersRepository

    public init(ordersRepository: OrdersRepository) {
        self.ordersRepository = ordersRepository
    }
}

