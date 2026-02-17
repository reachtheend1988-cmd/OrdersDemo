import SwiftUI

public struct AppRootView: View {
    private let environment: AppEnvironment

    public init(environment: AppEnvironment) {
        self.environment = environment
    }

    public var body: some View {
        NavigationView {
            OrderListView(environment: environment)
        }
        .navigationViewStyle(.stack)
    }
}

