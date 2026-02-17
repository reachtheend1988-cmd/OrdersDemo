import XCTest
@testable import OrdersDemo

@MainActor
final class OrderDetailsViewModelTests: XCTestCase {
    func testStatusUpdates_updateCurrentStatus() async {
        let id = UUID()
        let order = Order(
            id: id,
            customerName: "A",
            destination: "B",
            createdAt: Date(),
            status: .pending
        )

        let repo = MockOrdersRepository(
            orders: [order],
            fetchBehavior: .success(delaySeconds: 0),
            statusSequences: [id: [.inTransit, .delivered]],
            statusUpdateIntervalSeconds: 0,
            sleeper: .immediate
        )

        let vm = OrderDetailsViewModel(order: order, ordersRepository: repo)
        XCTAssertEqual(vm.currentStatus, .pending)

        vm.onAppear()

        let reachedDelivered = await eventually {
            vm.currentStatus == .delivered
        }
        XCTAssertTrue(reachedDelivered)
    }
}

