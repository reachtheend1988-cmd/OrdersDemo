import Foundation
import SwiftUI

/// Holds app-wide dependencies (e.g. the orders repository) and is injected via SwiftUI’s environment.

public struct OrdersAppEnvironment: Sendable {
    public var ordersRepository: OrdersRepository

    public init(ordersRepository: OrdersRepository) {
        self.ordersRepository = ordersRepository
    }
}

// MARK: - SwiftUI Environment

/// The app sets `ordersAppEnvironment` once at the root; child views read it from the environment.
private struct OrdersAppEnvironmentKey: EnvironmentKey {
    static let defaultValue: OrdersAppEnvironment = OrdersAppEnvironment(ordersRepository: MockOrdersRepository.demo())
}

public extension EnvironmentValues {
    var ordersAppEnvironment: OrdersAppEnvironment {
        get { self[OrdersAppEnvironmentKey.self] }
        set { self[OrdersAppEnvironmentKey.self] = newValue }
    }
}
