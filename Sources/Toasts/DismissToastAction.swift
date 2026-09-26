import SwiftUI

/// Identifies a presented toast, so it can be dismissed from code.
public struct ToastID: Hashable, Sendable {
  private let rawValue = UUID()

  internal init() {}
}

extension EnvironmentValues {
  /// Provides access to the toast dismissal action within the environment.
  ///
  /// This value is only available after calling `installToast()` on a parent view in the hierarchy.
  public internal(set) var dismissToast: DismissToastAction {
    get { self[DismissToastKey.self] }
    set { self[DismissToastKey.self] = newValue }
  }
}

/// Represents an action for dismissing toasts in SwiftUI views.
///
/// A dismissed toast collapses back into its circle and leaves, just as when its time runs out.
@MainActor
public struct DismissToastAction {
  internal weak var manager: ToastManager?

  /// Dismisses the toast with the given ID. Does nothing if it has already left.
  ///
  /// - Parameter id: The ID returned when the toast was presented.
  public func callAsFunction(_ id: ToastID) {
    guard let manager = checkedManager else { return }
    Task { await manager.dismiss(id) }
  }

  /// Dismisses every toast, including loading toasts.
  public func callAsFunction() {
    guard let manager = checkedManager else { return }
    Task { await manager.dismissAll() }
  }

  private var checkedManager: ToastManager? {
    #if DEBUG
      if manager == nil {
        print(
          "View.installToast must be called on a parent view to use EnvironmentValues.dismissToast."
        )
      }
    #endif
    return manager
  }
}

private enum DismissToastKey: EnvironmentKey {
  static let defaultValue: DismissToastAction = .init()
}
