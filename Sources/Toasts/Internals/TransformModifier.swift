import SwiftUI

/// Slides and shrinks a toast toward the screen edge as `progress` goes from 0 (in place) to 1
/// (off the edge), fading it out by `fadeEnd` of the way so it's gone before it reaches the edge.
internal struct TransformModifier: ViewModifier, Animatable {
  var progress: CGFloat
  var yOffset: CGFloat
  var scale: CGFloat
  var fadeEnd: CGFloat = 0.8

  nonisolated var animatableData: CGFloat {
    get { progress }
    set { progress = newValue }
  }

  func body(content: Content) -> some View {
    content
      .opacity(min(max(1 - progress / fadeEnd, 0), 1))
      .scaleEffect(1 - (1 - scale) * progress)
      .offset(y: yOffset * progress)
  }
}
