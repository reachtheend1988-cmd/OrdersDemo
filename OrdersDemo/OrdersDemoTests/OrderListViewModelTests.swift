import XCTest
@testable import OrdersDemo

@MainActor
final class OrderListViewModelTests: XCTestCase {
    func testReload_successTransitionsToLoaded() async {
        let order1 = Order(id: UUID(), customerName: "A", destination: "B", createdAt: Date(), status: .pending)
        let repo = MockOrdersRepository(
            orders: [order1],
            fetchBehavior: .success(delaySeconds: 0),
            statusSequences: [:],
            statusUpdateIntervalSeconds: 0,
            requestDelay: .immediate
        )

        let vm = OrderListViewModel(ordersRepository: repo)
        XCTAssertEqual(vm.state, .idle)

        vm.reload()
        XCTAssertEqual(vm.state, .loading)

        let didLoad = await eventually {
            if case .loaded = vm.state { return true }
            return false
        }
        XCTAssertTrue(didLoad)
    }

    func testReload_emptyTransitionsToEmpty() async {
        let repo = MockOrdersRepository(
            orders: [],
            fetchBehavior: .empty(delaySeconds: 0),
            statusSequences: [:],
            statusUpdateIntervalSeconds: 0,
            requestDelay: .immediate
        )

        let vm = OrderListViewModel(ordersRepository: repo)
        vm.reload()

        let didBecomeEmpty = await eventually {
            vm.state == .empty
        }
        XCTAssertTrue(didBecomeEmpty)
    }

    func testReload_failureTransitionsToFailed() async {
        let repo = MockOrdersRepository(
            orders: [],
            fetchBehavior: .failure(delaySeconds: 0),
            statusSequences: [:],
            statusUpdateIntervalSeconds: 0,
            requestDelay: .immediate
        )

        let vm = OrderListViewModel(ordersRepository: repo)
        vm.reload()

        let didFail = await eventually {
            if case .failed = vm.state { return true }
            return false
        }
        XCTAssertTrue(didFail)
    }

    func testFiltering_filtersByStatus() async {
        let pending = Order(id: UUID(), customerName: "A", destination: "X", createdAt: Date(), status: .pending)
        let delivered = Order(id: UUID(), customerName: "B", destination: "Y", createdAt: Date(), status: .delivered)

        let repo = MockOrdersRepository(
            orders: [pending, delivered],
            fetchBehavior: .success(delaySeconds: 0),
            statusSequences: [:],
            statusUpdateIntervalSeconds: 0,
            requestDelay: .immediate
        )

        let vm = OrderListViewModel(ordersRepository: repo)
        vm.reload()

        let loaded = await eventually {
            if case .loaded = vm.state { return true }
            return false
        }
        XCTAssertTrue(loaded)

        vm.filter = .pending
        XCTAssertEqual(vm.filteredOrders, [pending])

        vm.filter = .delivered
        XCTAssertEqual(vm.filteredOrders, [delivered])
    }

    func testReload_errorThenRetryTransitionsToLoaded() async {
        let order = Order(id: UUID(), customerName: "A", destination: "B", createdAt: Date(), status: .pending)

        let repo = TestOrdersRepository(fetchResults: [
            .failure(MockOrdersError.simulatedFailure),
            .success(OrdersPage(orders: [order], nextCursor: nil)),
        ])

        let vm = OrderListViewModel(ordersRepository: repo)

        vm.reload()
        let didFail = await eventually {
            if case .failed = vm.state { return true }
            return false
        }
        XCTAssertTrue(didFail)

        vm.reload()
        let didLoad = await eventually {
            if case .loaded = vm.state { return true }
            return false
        }
        XCTAssertTrue(didLoad)

        XCTAssertEqual(vm.filteredOrders, [order])
    }

    func testReload_emptyThenPopulatedTransitionsToLoaded() async {
        let order = Order(id: UUID(), customerName: "A", destination: "B", createdAt: Date(), status: .pending)

        let repo = TestOrdersRepository(fetchResults: [
            .success(OrdersPage(orders: [], nextCursor: nil)),
            .success(OrdersPage(orders: [order], nextCursor: nil)),
        ])

        let vm = OrderListViewModel(ordersRepository: repo)

        vm.reload()
        let didBecomeEmpty = await eventually {
            vm.state == .empty
        }
        XCTAssertTrue(didBecomeEmpty)

        vm.reload()
        let didLoad = await eventually {
            if case .loaded = vm.state { return true }
            return false
        }
        XCTAssertTrue(didLoad)

        XCTAssertEqual(vm.filteredOrders, [order])
    }
}

