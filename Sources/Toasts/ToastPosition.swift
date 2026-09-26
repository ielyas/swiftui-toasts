import UIKit

/// Defines the vertical position where toasts will appear on screen.
public enum ToastPosition {
  /// Toast appears at the top of the screen.
  case top
  /// Toast appears at the bottom of the screen.
  case bottom

  /// The position toasts use unless you pass one: bottom on iPad, top everywhere else.
  @MainActor
  public static var `default`: ToastPosition {
    UIDevice.current.userInterfaceIdiom == .pad ? .bottom : .top
  }
}
