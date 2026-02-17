import SwiftUI

public extension OrderStatus {
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .inTransit: return "In transit"
        case .delivered: return "Delivered"
        }
    }

    var tint: Color {
        switch self {
        case .pending: return .orange
        case .inTransit: return .blue
        case .delivered: return .green
        }
    }
}

