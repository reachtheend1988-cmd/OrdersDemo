import XCTest
@testable import OrdersDemo

@MainActor
final class MockOrdersRepositoryTests: XCTestCase {
    func testFetchOrders_successReturnsOrders() async throws {
        let order = Order(
            id: UUID(),
            customerName: "A",
            destination: "B",
            createdAt: Date(),
            status: .pending
        )

        let repo = MockOrdersRepository(
            orders: [order],
            fetchBehavior: .success(delaySeconds: 0),
            statusSequences: [:],
            statusUpdateIntervalSeconds: 0,
            requestDelay: .immediate
        )

        let page = try await repo.fetchOrders(cursor: nil, limit: 10)
        XCTAssertEqual(page.orders, [order])
        XCTAssertNil(page.nextCursor)
    }

    func testFetchOrders_emptyReturnsEmptyArray() async throws {
        let repo = MockOrdersRepository(
            orders: [Order(id: UUID(), customerName: "A", destination: "B", createdAt: Date(), status: .pending)],
            fetchBehavior: .empty(delaySeconds: 0),
            statusSequences: [:],
            statusUpdateIntervalSeconds: 0,
            requestDelay: .immediate
        )

        let page = try await repo.fetchOrders(cursor: nil, limit: 10)
        XCTAssertEqual(page.orders, [])
        XCTAssertNil(page.nextCursor)
    }

    func testFetchOrders_failureThrows() async {
        let repo = MockOrdersRepository(
            orders: [],
            fetchBehavior: .failure(delaySeconds: 0),
            statusSequences: [:],
            statusUpdateIntervalSeconds: 0,
            requestDelay: .immediate
        )

        do {
            _ = try await repo.fetchOrders(cursor: nil, limit: 10)
            XCTFail("Expected fetchOrders to throw")
        } catch {
            XCTAssertEqual(error as? MockOrdersError, .simulatedFailure)
        }
    }

    func testFetchOrders_cursorPaginates() async throws {
        let orders = (1...5).map { i in
            Order(
                id: UUID(),
                customerName: "User\(i)",
                destination: "D\(i)",
                createdAt: Date().addingTimeInterval(TimeInterval(-i * 60)),
                status: .pending
            )
        }
        let repo = MockOrdersRepository(
            orders: orders,
            fetchBehavior: .success(delaySeconds: 0),
            statusSequences: [:],
            statusUpdateIntervalSeconds: 0,
            requestDelay: .immediate
        )

        let first = try await repo.fetchOrders(cursor: nil, limit: 2)
        XCTAssertEqual(first.orders.count, 2)
        XCTAssertNotNil(first.nextCursor)

        let second = try await repo.fetchOrders(cursor: first.nextCursor, limit: 2)
        XCTAssertEqual(second.orders.count, 2)
        XCTAssertNotNil(second.nextCursor)

        let third = try await repo.fetchOrders(cursor: second.nextCursor, limit: 2)
        XCTAssertEqual(third.orders.count, 1)
        XCTAssertNil(third.nextCursor)
    }

    func testStatusUpdates_yieldsConfiguredSequence() async {
        let id = UUID()
        let order = Order(id: id, customerName: "A", destination: "B", createdAt: Date(), status: .pending)
        let repo = MockOrdersRepository(
            orders: [order],
            fetchBehavior: .success(delaySeconds: 0),
            statusSequences: [:],
            statusUpdateIntervalSeconds: 0,
            requestDelay: .immediate
        )

        _ = try? await repo.fetchOrders(cursor: nil, limit: 10)

        var received: [OrderStatus] = []
        for await status in repo.statusUpdates(for: id).values {
            received.append(status)
        }
        XCTAssertEqual(received, [.inTransit, .delivered])
    }
}

