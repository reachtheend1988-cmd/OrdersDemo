import Foundation

/// Simulates delay for mock API requests (e.g. fetch latency). Use `.immediate` in tests for no delay; use `.taskSleep` in the app for realistic delay.
public struct RequestDelay: Sendable {
    private let _sleep: @Sendable (TimeInterval) async -> Void

    public init(_ sleep: @escaping @Sendable (TimeInterval) async -> Void) {
        self._sleep = sleep
    }

    public func sleep(seconds: TimeInterval) async {
        await _sleep(seconds)
    }
}

public extension RequestDelay {
    /// No delay; use in tests so requests complete immediately.
    static let immediate = RequestDelay { _ in }

    /// Real delay using `Task.sleep`; use in the app to simulate API latency.
    static let taskSleep = RequestDelay { seconds in
        guard seconds > 0 else { return }
        let nanoseconds = UInt64(seconds * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanoseconds)
    }
}
