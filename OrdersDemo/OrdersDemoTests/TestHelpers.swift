import Foundation
import XCTest
@testable import OrdersDemo

@MainActor
func eventually(
    timeout: TimeInterval = 1.0,
    pollIntervalNanoseconds: UInt64 = 20_000_000,
    _ predicate: @escaping @MainActor () -> Bool
) async -> Bool {
    let start = Date()
    while Date().timeIntervalSince(start) < timeout {
        if predicate() { return true }
        try? await Task.sleep(nanoseconds: pollIntervalNanoseconds)
    }
    return predicate()
}

