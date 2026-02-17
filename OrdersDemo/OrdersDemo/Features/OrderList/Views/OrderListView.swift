import SwiftUI

/// Public entry: reads app environment from SwiftUI Environment; no parameters. Bridges to content that needs environment for StateObject init.
public struct OrderListView: View {
    @Environment(\.appEnvironment) private var environment

    public var body: some View {
        OrderListViewContent(environment: environment)
    }
}

/// Internal: holds StateObject and needs environment at init. Only OrderListView (which reads Environment) should construct this.
struct OrderListViewContent: View {
    @StateObject private var viewModel: OrderListViewModel
    private let environment: AppEnvironment

    init(environment: AppEnvironment) {
        self.environment = environment
        _viewModel = StateObject(wrappedValue: OrderListViewModel(ordersRepository: environment.ordersRepository))
    }

    var body: some View {
        stateView
            .navigationTitle("Orders")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Reload") { viewModel.reload() }
                        .accessibilityLabel("Reload orders")
                }
            }
            .onAppear { viewModel.onAppear() }
    }

    @ViewBuilder
    private var stateView: some View {
        switch viewModel.state {
        case .idle, .loading:
            OrderListLoadingView()
        case .empty:
            OrderListEmptyView()
        case .failed(let error):
            OrderListFailedView(error: error, onRetry: { viewModel.reload() })
        case .loaded:
            OrderListLoadedView(viewModel: viewModel)
        }
    }
}
