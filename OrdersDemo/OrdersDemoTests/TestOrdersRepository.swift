import Combine
import Foundation
import OrdersDemo

/// A tiny, deterministic repository stub for ViewModel tests.
/// It returns a predefined sequence of fetch results and ignores status updates.
final class TestOrdersRepository: OrdersRepository, @unchecked Sendable {
    private let lock = NSLock()
    private var fetchResults: [Result<OrdersPage, Error>]

    init(fetchResults: [Result<OrdersPage, Error>]) {
        self.fetchResults = fetchResults
    }

    func fetchOrders(cursor: String?, limit: Int) async throws -> OrdersPage {
        lock.lock()
        defer { lock.unlock() }

        guard !fetchResults.isEmpty else {
            return OrdersPage(orders: [], nextCursor: nil)
        }
        let result = fetchResults.removeFirst()
        switch result {
        case .success(let page):
            return page
        case .failure(let error):
            throw error
        }
    }

    func statusUpdates(for orderID: UUID) -> AnyPublisher<OrderStatus, Never> {
        Empty(completeImmediately: true).eraseToAnyPublisher()
    }
}

