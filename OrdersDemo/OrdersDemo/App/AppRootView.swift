import SwiftUI

public struct AppRootView: View {
    public var body: some View {
        NavigationView {
            OrderListView()
        }
        .navigationViewStyle(.stack)
    }
}

