import SwiftUI

public struct OrderListFilteredEmptyView: View {
    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No matching orders")
                .font(.title2.weight(.semibold))
            Text("Try a different filter.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
