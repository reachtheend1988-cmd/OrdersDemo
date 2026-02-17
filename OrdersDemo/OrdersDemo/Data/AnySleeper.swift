import Foundation

public struct AnySleeper: Sendable {
    private let _sleep: @Sendable (TimeInterval) async -> Void

    public init(_ sleep: @escaping @Sendable (TimeInterval) async -> Void) {
        self._sleep = sleep
    }

    public func sleep(seconds: TimeInterval) async {
        await _sleep(seconds)
    }
}

public extension AnySleeper {
    nonisolated static let immediate = AnySleeper { _ in }

    nonisolated static let taskSleep = AnySleeper { seconds in
        guard seconds > 0 else { return }
        let nanoseconds = UInt64(seconds * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanoseconds)
    }
}

