import Foundation

public struct Order: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var customerName: String
    public var destination: String
    public var createdAt: Date
    public var status: OrderStatus

    public init(
        id: UUID,
        customerName: String,
        destination: String,
        createdAt: Date,
        status: OrderStatus
    ) {
        self.id = id
        self.customerName = customerName
        self.destination = destination
        self.createdAt = createdAt
        self.status = status
    }
}

