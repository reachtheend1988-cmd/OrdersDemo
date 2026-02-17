import SwiftUI

public struct OrderDetailsView: View {
    @StateObject private var viewModel: OrderDetailsViewModel

    public init(environment: OrdersAppEnvironment, order: Order) {
        _viewModel = StateObject(
            wrappedValue: OrderDetailsViewModel(
                order: order,
                ordersRepository: environment.ordersRepository
            )
        )
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                statusCard
                updatesCard
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Order details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(viewModel.order.customerName)
                .font(.title2.weight(.semibold))

            Text("Deliver to \(viewModel.order.destination)")
                .foregroundStyle(.secondary)

            Text("Created \(viewModel.order.createdAt, style: .relative) ago")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var statusCard: some View {
        GroupBox("Current status") {
            HStack(alignment: .center, spacing: 12) {
                Circle()
                    .fill(viewModel.currentStatus.tint)
                    .frame(width: 10, height: 10)
                    .accessibilityHidden(true)

                Text(viewModel.currentStatus.displayName)
                    .font(.headline)

                Spacer(minLength: 8)

                Text(viewModel.currentStatus.rawValue)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    private var updatesCard: some View {
        GroupBox("Updates") {
            VStack(alignment: .leading, spacing: 8) {
                if viewModel.isListeningForUpdates {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Listening for status updates…")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("No more updates.")
                        .foregroundStyle(.secondary)
                }

                if let lastUpdateAt = viewModel.lastUpdateAt {
                    Text("Last update: \(lastUpdateAt.formatted(date: .abbreviated, time: .standard))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

