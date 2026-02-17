import SwiftUI

public struct OrderListLoadingView: View {
    public var body: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading orders…")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
