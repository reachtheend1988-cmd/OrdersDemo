import Foundation

public enum OrderStatusFilter: String, CaseIterable, Identifiable, Hashable, Sendable {
    case all = "ALL"
    case pending = "PENDING"
    case inTransit = "IN_TRANSIT"
    case delivered = "DELIVERED"

    public var id: String { rawValue }

    public var status: OrderStatus? {
        switch self {
        case .all: return nil
        case .pending: return .pending
        case .inTransit: return .inTransit
        case .delivered: return .delivered
        }
    }

    public var displayName: String {
        switch self {
        case .all: return "All"
        case .pending: return "Pending"
        case .inTransit: return "In transit"
        case .delivered: return "Delivered"
        }
    }
}
