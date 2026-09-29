import Foundation
import SwiftUI

/// Represents a toast notification with customizable content and behavior.
public struct ToastValue {
  internal var icon: AnyView?
  internal var message: String
  internal var button: ToastButton?
  /// The haptic played as the toast appears; `nil` for a loading toast, which plays its result's.
  internal var kind: ToastKind?
  /// Whether the toast shows a close button inside it.
  internal var showsDismissButton: Bool
  /// If nil, the toast will persist and not disappear. Used when displaying a loading toast.
  internal var duration: TimeInterval?

  /// Creates a new toast with the specified content and behavior.
  ///
  /// - Parameters:
  ///   - icon: An optional view to display as an icon in the toast.
  ///   - message: The text content of the toast.
  ///   - kind: What the toast communicates, which decides the haptic it plays as it appears. Default is `.info`.
  ///   - button: An optional action button to display in the toast.
  ///   - showsDismissButton: Whether to show a close button inside the toast, so it can be dismissed with a tap. Default is `false`.
  ///   - duration: How long the toast should be displayed before automatically dismissing, in seconds. Clamped between 0 and 10 seconds. Default is 3.0.
  public init(
    icon: (any View)? = nil,
    message: String,
    kind: ToastKind = .info,
    button: ToastButton? = nil,
    showsDismissButton: Bool = false,
    duration: TimeInterval = 3.0
  ) {
    self.icon = icon.map { AnyView($0) }
    self.message = message
    self.kind = kind
    self.button = button
    self.showsDismissButton = showsDismissButton
    self.duration = min(max(0, duration), 10)
  }
  @_disfavoredOverload
  internal init(
    icon: (any View)? = nil,
    message: String,
    kind: ToastKind? = nil,
    button: ToastButton? = nil,
    showsDismissButton: Bool = false,
    duration: TimeInterval? = nil
  ) {
    self.icon = icon.map { AnyView($0) }
    self.message = message
    self.kind = kind
    self.button = button
    self.showsDismissButton = showsDismissButton
    self.duration = duration
  }
}

/// Represents an action button that can be displayed within a toast.
public struct ToastButton {
  /// The text to display on the button. With a `systemImage`, VoiceOver reads it instead.
  public var title: String

  /// An SF Symbol shown instead of the title, in a small tinted circle. `nil` shows the title.
  public var systemImage: String?

  /// The color of the button text.
  public var color: Color

  /// The action to perform when the button is tapped.
  public var action: () -> Void

  /// Creates a new toast button with the specified title, color, and action.
  ///
  /// - Parameters:
  ///   - title: The text to display on the button, or its VoiceOver label with a `systemImage`.
  ///   - systemImage: An SF Symbol to show instead of the title. Default is `nil`.
  ///   - color: The color of the button text. Default is `.primary`.
  ///   - action: The closure to execute when the button is tapped.
  public init(
    title: String,
    systemImage: String? = nil,
    color: Color = .primary,
    action: @escaping () -> Void
  ) {
    self.title = title
    self.systemImage = systemImage
    self.color = color
    self.action = action
  }
}
