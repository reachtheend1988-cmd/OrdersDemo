import Foundation
import SwiftUI

public struct OrdersAppEnvironment: Sendable {
    public var ordersRepository: OrdersRepository

    public init(ordersRepository: OrdersRepository) {
        self.ordersRepository = ordersRepository
    }
}

// MARK: - SwiftUI Environment (Dependency Inversion: app injects protocol, views read from Environment)

private struct OrdersAppEnvironmentKey: EnvironmentKey {
    static let defaultValue: OrdersAppEnvironment = OrdersAppEnvironment(ordersRepository: MockOrdersRepository.demo())
}

public extension EnvironmentValues {
    var ordersAppEnvironment: OrdersAppEnvironment {
        get { self[OrdersAppEnvironmentKey.self] }
        set { self[OrdersAppEnvironmentKey.self] = newValue }
    }
}
