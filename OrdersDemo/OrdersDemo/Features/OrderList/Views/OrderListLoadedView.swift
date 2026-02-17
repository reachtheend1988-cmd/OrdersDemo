import SwiftUI

public struct OrderListLoadedView: View {
    @ObservedObject private var viewModel: OrderListViewModel
    @Environment(\.ordersAppEnvironment) private var environment
    @State private var selectedOrder: Order?

    public init(viewModel: OrderListViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 8) {
            // Keep navigation state outside of list rows so list updates (status changes)
            // don’t accidentally dismiss the details screen on iOS 15 `NavigationView`.
            NavigationLink(
                isActive: Binding(
                    get: { selectedOrder != nil },
                    set: { isActive in
                        if !isActive { selectedOrder = nil }
                    }
                ),
                destination: {
                    Group {
                        if let selectedOrder {
                            OrderDetailsView(environment: environment, order: selectedOrder)
                        } else {
                            EmptyView()
                        }
                    }
                },
                label: { EmptyView() }
            )
            .hidden()

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
                Button {
                    selectedOrder = order
                } label: {
                    OrderRowView(order: order)
                }
                .buttonStyle(.plain)
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
