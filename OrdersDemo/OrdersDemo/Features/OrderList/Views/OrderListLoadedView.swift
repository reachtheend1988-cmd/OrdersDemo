import SwiftUI

public struct OrderListLoadedView: View {
    @ObservedObject private var viewModel: OrderListViewModel
    @Environment(\.appEnvironment) private var environment

    public init(viewModel: OrderListViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 8) {
            Picker("Filter", selection: $viewModel.filter) {
                ForEach(OrderStatusFilter.allCases) { filter in
                    Text(filter.displayName).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding([.horizontal, .top])

            if viewModel.filteredOrders.isEmpty {
                OrderListFilteredEmptyView()
            } else {
                orderList
            }
        }
    }

    private var orderList: some View {
        List {
            ForEach(viewModel.filteredOrders) { order in
                NavigationLink {
                    OrderDetailsView(
                        environment: environment,
                        order: order
                    )
                } label: {
                    OrderRowView(order: order)
                }
                .onAppear {
                    if viewModel.filter == .all, order.id == viewModel.lastLoadedOrderId {
                        viewModel.loadMoreIfNeeded()
                    }
                }
            }
            if viewModel.hasMorePages, viewModel.filter == .all {
                HStack {
                    Spacer()
                    if viewModel.isLoadingMore {
                        ProgressView()
                            .padding()
                    } else {
                        Text("Pull for more")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding()
                    }
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
    }
}
