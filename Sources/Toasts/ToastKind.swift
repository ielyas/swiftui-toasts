import SwiftUI

/// What a toast communicates, which decides the haptic it plays as it appears.
///
/// Following the Human Interface Guidelines, each kind uses the system haptic whose meaning
/// matches it: the success, warning and error notification patterns for outcomes, and a soft
/// impact for neutral information, as the glass lands and expands. The system mutes haptics when
/// the person turns off System Haptics.
public enum ToastKind: Sendable, Hashable, CaseIterable {
  /// Neutral information, such as a new notification or a change of state.
  case info
  /// A task or action completed successfully.
  case success
  /// A task or action produced a warning.
  case warning
  /// A task or action failed.
  case error

  internal var sensoryFeedback: SensoryFeedback {
    switch self {
    case .info: .impact(flexibility: .soft, intensity: 0.7)
    case .success: .success
    case .warning: .warning
    case .error: .error
    }
  }
}
