import Combine
import Foundation

@MainActor
public final class OrderDetailsViewModel: ObservableObject {
    @Published public private(set) var currentStatus: OrderStatus
    @Published public private(set) var isListeningForUpdates: Bool = false
    @Published public private(set) var lastUpdateAt: Date?

    public let order: Order

    private let ordersRepository: OrdersRepository
    private var updatesCancellable: AnyCancellable?

    public init(order: Order, ordersRepository: OrdersRepository) {
        self.order = order
        self.ordersRepository = ordersRepository
        self.currentStatus = order.status
    }

    public func onAppear() {
        startListeningForUpdatesIfNeeded()
    }

    public func onDisappear() {
        updatesCancellable?.cancel()
        updatesCancellable = nil
        isListeningForUpdates = false
    }

    private func startListeningForUpdatesIfNeeded() {
        guard updatesCancellable == nil else { return }

        isListeningForUpdates = true
        updatesCancellable = ordersRepository
            .statusUpdates(for: order.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] _ in
                    self?.isListeningForUpdates = false
                },
                receiveValue: { [weak self] status in
                    guard let self else { return }
                    self.currentStatus = status
                    self.lastUpdateAt = Date()
                }
            )
    }
}

