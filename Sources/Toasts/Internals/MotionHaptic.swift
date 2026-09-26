import SwiftUI

/// Light taps that mark the start and end of a toast's motion, around its kind's haptic.
///
/// In: a tap as the circle starts sliding in, the kind's haptic as it expands, and a tap as the
/// toast settles. Out: a tap as it starts collapsing, and another as it closes into the circle and
/// leaves. They're deliberately faint, so the kind's haptic stays the one that carries meaning, and
/// they're skipped with Reduce Motion on, when there's no motion to accompany.
internal enum MotionHaptic: Hashable {
  case entering
  case settled
  case leaving

  internal var sensoryFeedback: SensoryFeedback {
    switch self {
    case .entering, .leaving: .impact(flexibility: .soft, intensity: 0.35)
    case .settled: .impact(flexibility: .solid, intensity: 0.45)
    }
  }

  /// Played as a collapsed toast leaves, from the root view, since the toast's own view is gone.
  internal static let left: SensoryFeedback = .impact(flexibility: .solid, intensity: 0.45)
}
