import SwiftUI

internal struct ToastRootView: View {

  @ObservedObject var manager: ToastManager
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    main
      .onAppear(perform: manager.onAppear)
      // A toast that closed back into its circle taps once more as it leaves.
      .sensoryFeedback(trigger: manager.models.count) { oldCount, newCount in
        newCount < oldCount && !reduceMotion ? MotionHaptic.left : nil
      }
  }

  @ViewBuilder
  private var main: some View {
    let isTop = manager.position == .top
    VStack(spacing: 8) {
      if !isTop { Spacer() }

      let models = isTop ? manager.models.reversed() : manager.models
      ForEach(manager.isAppeared ? models : []) { model in
        ToastInteractingView(model: model, manager: manager)
          .transition(transition(isTop: isTop))
      }

      if isTop { Spacer() }
    }
    .animation(
      .spring(duration: removalAnimationDuration),
      value: Tuple(count: manager.models.count, isAppeared: manager.isAppeared)
    )
    .padding(.horizontal)
    .padding(.vertical, 8)
    // Top toasts sit just below the device's safe area, under the status bar or Dynamic Island.
    // Bottom toasts follow the insets the safe-area observers report, so they clear the tab bar
    // and rise above the keyboard.
    .padding(isTop ? EdgeInsets() : manager.safeAreaInsets)
    .animation(.spring(duration: removalAnimationDuration), value: manager.safeAreaInsets)
    .ignoresSafeArea(edges: isTop ? [] : .all)
  }

  private func transition(isTop: Bool) -> AnyTransition {
    if reduceMotion { return .opacity }
    return .modifier(
      active: TransformModifier(progress: 1, yOffset: isTop ? -96 : 96, scale: 0.5),
      identity: TransformModifier(progress: 0, yOffset: isTop ? -96 : 96, scale: 0.5)
    )
  }
}

private struct Tuple: Equatable {
  var count: Int
  var isAppeared: Bool
}
