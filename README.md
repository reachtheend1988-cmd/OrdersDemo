# OrdersDemo – Delivery Tracking (Take‑Home)

This repo implements the two‑screen iOS Delivery Tracking app described in `instructions.md`.

## Architecture

- **UI**: SwiftUI
- **Presentation**: MVVM (`OrderListViewModel`, `OrderDetailsViewModel`)
- **Domain**: `Order`, `OrderStatus` (no UI formatting concerns)
- **Data**: `OrdersRepository` protocol + `MockOrdersRepository` implementation
- **State**: Explicit `LoadState<Value>` for predictable UI rendering
- **Dependency Injection**: `AppEnvironment` is created in `OrdersDemoApp` and passed down to features

### Data flow

1. `OrdersDemoApp` builds an `AppEnvironment` using `MockOrdersRepository.demo()`.
2. `AppRootView` hosts a `NavigationView` (stack style) for compatibility with the deployment target.
3. **Order List**
   - `OrderListViewModel.reload()` transitions: `idle → loading → loaded/empty/failed`.
   - `OrderListView` renders directly from `LoadState` (no implicit “isLoading” flags).
   - Filtering uses `OrderStatusFilter` and derives `filteredOrders` from the loaded domain data.
4. **Order Details**
   - `OrderDetailsViewModel` starts an `AsyncStream<OrderStatus>` listener on appear.
   - The mock repository yields status updates over time to simulate polling/streaming.

## UI requirements checklist

- **Two screens**: Order list + order details.
- **Filter**: PENDING / IN_TRANSIT / DELIVERED (plus “All” for convenience).
- **Loading / empty / error states**: Explicitly modelled and shown.
- **Adaptive layout**: Uses SwiftUI layout primitives (`List`, `ScrollView`, `GroupBox`, system typography) and avoids hard‑coded sizing.

## Testing strategy

Tests are deterministic and focused on state and business logic.

- **Mock data source behaviour**
  - `MockOrdersRepositoryTests` verifies success/empty/failure and status update sequences.
- **State transitions**
  - `OrderListViewModelTests` verifies `loading → loaded`, `loading → empty`, `loading → failed`, plus filtering.
- **Details updates**
  - `OrderDetailsViewModelTests` verifies the view model consumes the status update stream.

The mock repository supports injected delay via `RequestDelay` so tests can run with `.immediate` (no real timers).

## How to run

### Run the app

Open `OrdersDemo/OrdersDemo/OrdersDemo.xcodeproj` in Xcode and run the `OrdersDemo` scheme on an iOS Simulator.

### Run tests (Xcode)

In Xcode, select the `OrdersDemo` scheme and run **Product → Test**.

### Run tests (CLI)

From `OrdersDemo/OrdersDemo`:

```bash
xcodebuild -project "OrdersDemo.xcodeproj" -scheme "OrdersDemo" -sdk iphonesimulator test
```

## Trade‑offs (timebox)

- **Simplified due to time:** Kept networking out (per spec) and focused on **predictable state + testability**. UI is intentionally simple, relying on system components for responsiveness and accessibility defaults.
- **Would refactor next:** Replace mock `AsyncStream` with a real polling or WebSocket adapter behind the same `OrdersRepository` interface; add an explicit “Error → retry” unit test (reload after failure and assert transition to loaded).

## Senior-level notes

### Domain vs UI models

- Domain types (`Order`, `OrderStatus`) avoid presentation formatting.
- UI concerns (colors, human readable strings) live in `Shared/OrderStatus+Presentation.swift`.
- This reduces coupling if the API payload changes (domain mapping can change without rewriting view code).

### Testability by design

- `OrdersRepository` enables dependency injection and isolated tests.
- `LoadState` makes transitions explicit and easy to assert.
- `RequestDelay` removes real time from tests (use `.immediate` in tests).

### Safe evolution (e.g. adding `CANCELLED`)

If a new status is introduced:

- **Domain**: add a new `OrderStatus` case.
- **Filtering**: update `OrderStatusFilter` if needed.
- **UI**: update `OrderStatus+Presentation` (string + tint).
- **Tests**: add a small set of assertions ensuring filtering and presentation behave as expected.

## Future improvements (production readiness)

- **Offline support:** Cache orders locally (e.g. Core Data or SwiftData), sync when online, and show last-known state with a “last updated” indicator.
- **Error handling:** Retry with backoff, user-facing error messages with recovery actions, and optional reporting/crash analytics.
- **CI:** GitHub Actions (or similar) to build and run tests on every push; optionally run on multiple iOS versions.
- **Performance:** Pagination or virtualisation for large order lists; minimise work on the main actor for status update streams.
- **Accessibility:** Audit with VoiceOver, add explicit labels and hints where needed, and ensure dynamic type and contrast are respected.

---

### Thought exercise: real-time map tracking

To add driver tracking on a map while staying testable:

- Introduce a `DriverLocationProviding` protocol (stream/poll interface returning coordinates).
- Keep the map SDK behind an adapter layer (e.g., `MapViewRepresentable` that consumes plain structs).
- Test the view model/reducer logic using a fake location provider; keep map rendering in thin UI glue.

