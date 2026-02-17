import Foundation
import SwiftUI

public struct AppEnvironment: Sendable {
    public var ordersRepository: OrdersRepository

    public init(ordersRepository: OrdersRepository) {
        self.ordersRepository = ordersRepository
    }
}

// MARK: - SwiftUI Environment (Dependency Inversion: app injects protocol, views read from Environment)

private struct AppEnvironmentKey: EnvironmentKey {
    static let defaultValue: AppEnvironment = AppEnvironment(ordersRepository: MockOrdersRepository.demo())
}

public extension EnvironmentValues {
    var appEnvironment: AppEnvironment {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}

