import SwiftUI

public struct OrderRowView: View {
    private let order: Order

    public init(order: Order) {
        self.order = order
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(order.customerName)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(order.destination)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(order.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Text(order.status.displayName)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(order.status.tint.opacity(0.15), in: Capsule())
                .foregroundStyle(order.status.tint)
                .accessibilityLabel("Status: \(order.status.displayName)")
        }
        .padding(.vertical, 4)
    }
}
