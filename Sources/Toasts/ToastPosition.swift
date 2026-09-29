#if canImport(UIKit)
  import UIKit
#endif

/// Defines the vertical position where toasts will appear on screen.
public enum ToastPosition {
  /// Toast appears at the top of the screen.
  case top
  /// Toast appears at the bottom of the screen.
  case bottom

  /// The position toasts use unless you pass one: bottom on iPad and Mac, top on iPhone and Apple TV.
  @MainActor
  public static var `default`: ToastPosition {
    #if os(macOS)
      .bottom
    #elseif os(tvOS)
      .top
    #else
      UIDevice.current.userInterfaceIdiom == .pad ? .bottom : .top
    #endif
  }
}
