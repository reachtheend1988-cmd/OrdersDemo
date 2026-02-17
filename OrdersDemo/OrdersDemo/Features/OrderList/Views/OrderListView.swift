import SwiftUI

public struct OrderListView: View {
    @StateObject private var viewModel: OrderListViewModel

    public init(environment: OrdersAppEnvironment) {
        _viewModel = StateObject(wrappedValue: OrderListViewModel(ordersRepository: environment.ordersRepository))
    }

    public var body: some View {
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
