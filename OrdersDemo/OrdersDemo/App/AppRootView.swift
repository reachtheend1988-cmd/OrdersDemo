import SwiftUI

public struct AppRootView: View {
    @Environment(\.ordersAppEnvironment) private var environment

    public var body: some View {
        NavigationView {
            OrderListView(environment: environment)
        }
        .navigationViewStyle(.stack)
    }
}

