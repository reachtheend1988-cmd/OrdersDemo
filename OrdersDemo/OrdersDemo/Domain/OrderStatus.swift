import Foundation

public enum OrderStatus: String, CaseIterable, Codable, Hashable, Sendable {
    case pending = "PENDING"
    case inTransit = "IN_TRANSIT"
    case delivered = "DELIVERED"
}

