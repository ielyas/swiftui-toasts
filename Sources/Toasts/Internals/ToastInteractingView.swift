import SwiftUI

internal struct ToastInteractingView: View {

  @ObservedObject var model: ToastModel
  let manager: ToastManager
  @GestureState private var yOffset: CGFloat?
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  private var isDragging: Bool { yOffset != nil }

  /// Everything the auto-dismiss timer depends on. The timer runs while the toast has a duration
  /// and is neither being dragged nor showing its full message, and restarts from the beginning
  /// whenever any of these change (e.g. after a drag ends or the message is collapsed).
  private var dismissTimer: DismissTimer {
    DismissTimer(
      delay: manager.dismissDelay(for: model),
      isPaused: isDragging || model.isMessageExpanded
    )
  }

  var body: some View {
    main
      .task(id: dismissTimer) {
        guard !dismissTimer.isPaused else { return }
        await manager.startRemovalTask(for: model)
      }
      .task { await expand() }
  }

  /// Lets the circle finish sliding in, then morphs it into the full toast.
  private func expand() async {
    guard !model.isExpanded, !model.isDismissing else { return }
    if reduceMotion {
      model.isExpanded = true
      return
    }
    do {
      try await Task.sleep(for: .seconds(removalAnimationDuration))
    } catch {
      return
    }
    guard !model.isDismissing else { return }
    withAnimation(morphAnimation) {
      model.isExpanded = true
    }
  }

  @MainActor
  private var main: some View {
    ToastView(model: model)
      // Measured inside the offset, so the frame follows the toast while it's dragged.
      .onGeometryChange(for: CGRect.self, of: { $0.frame(in: .global) }) { frame in
        manager.setFrame(frame, for: model)
      }
      .onDisappear {
        manager.setFrame(nil, for: model)
      }
      .offset(y: yOffset ?? 0)
      // Simultaneous, so tapping the toast to expand its message never blocks swiping it away.
      .simultaneousGesture(dragGesture)
      .animation(.spring, value: isDragging)
  }

  @MainActor
  private var dragGesture: some Gesture {
    DragGesture(minimumDistance: 0)
      .updating($yOffset) { value, state, _ in
        let translation = value.translation.height
        if model.duration == nil {
          state = translation * 0.5
        } else {
          let isTopPosition = manager.position == .top
          let shouldReduceTranslation = (isTopPosition && translation > 0) || (!isTopPosition && translation < 0)
          state = shouldReduceTranslation ? translation * 0.5 : translation
        }
      }
      .onEnded { value in
        if model.duration == nil { return }
        let threshold: CGFloat = 48 / 2
        let draggedAmount = manager.position == .top ? -value.translation.height : value.translation.height
        if draggedAmount > threshold {
          Task { await manager.dismiss(model) }
        }
      }
  }
}

private struct DismissTimer: Equatable {
  var delay: TimeInterval?
  var isPaused: Bool
}
