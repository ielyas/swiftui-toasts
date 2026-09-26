import SwiftUI

@MainActor
internal final class ToastManager: ObservableObject {

  @Published internal var position: ToastPosition = .top
  @Published internal private(set) var models: [ToastModel] = []
  @Published internal private(set) var isAppeared = false
  @Published internal var safeAreaInsets: EdgeInsets = .init()
  private var dismissOverlayTask: Task<Void, any Error>?
  /// Each visible toast's frame in the toast window, which decides the touches the window takes.
  private var toastFrames: [ObjectIdentifier: CGRect] = [:]

  internal var isPresented: Bool {
    !models.isEmpty || isAppeared
  }

  nonisolated init() {}

  internal func onAppear() {
    isAppeared = true
  }

  @discardableResult
  internal func append(_ toast: ToastValue) -> ToastModel {
    dismissOverlayTask?.cancel()
    dismissOverlayTask = nil
    let model = ToastModel(value: toast)
    models.append(model)
    announceToAccessibility(toast.message)
    return model
  }

  internal func setFrame(_ frame: CGRect?, for model: ToastModel) {
    toastFrames[ObjectIdentifier(model)] = frame
  }

  internal func containsToast(at point: CGPoint) -> Bool {
    toastFrames.values.contains { $0.contains(point) }
  }

  internal func remove(_ model: ToastModel) {
    setFrame(nil, for: model)
    if let index = self.models.firstIndex(where: { $0 === model }) {
      self.models.remove(at: index)
    }
    if models.isEmpty {
      dismissOverlayTask = Task {
        try await Task.sleep(for: .seconds(removalAnimationDuration))
        isAppeared = false
      }
    }
  }

  /// Collapses the toast (and its button) back into a circle, then removes it.
  internal func dismiss(_ model: ToastModel) async {
    guard !model.isDismissing else { return }
    model.isDismissing = true
    if model.isExpanded {
      withAnimation(morphAnimation) {
        model.isMessageExpanded = false
        model.isExpanded = false
      }
      // The collapse runs to completion even if the caller is cancelled mid-way.
      try? await Task.sleep(for: .seconds(morphAnimationDuration))
    }
    remove(model)
  }

  /// How long the toast stays before dismissing itself, or `nil` if it stays until removed.
  internal func dismissDelay(for model: ToastModel) -> TimeInterval? {
    guard let duration = model.value.duration else { return nil }
    return model.hasCollapsedMessage ? collapsedMessageDismissDelay : duration
  }

  internal func startRemovalTask(for model: ToastModel) async {
    if let duration = dismissDelay(for: model) {
      do {
        try await Task.sleep(for: .seconds(duration))
        // An expanded message stays until the person collapses or dismisses it.
        guard !model.isMessageExpanded else { return }
        await dismiss(model)
      } catch {}
    }
  }

  @discardableResult
  internal func append<V>(
    message: String,
    task: sending () async throws -> sending V,
    onSuccess: (V) -> ToastValue,
    onFailure: (any Error) -> ToastValue
  ) async throws -> sending V {
    let model = append(ToastValue(icon: LoadingView(), message: message, duration: nil))
    do {
      let value = try await task()
      let successToast = onSuccess(value)
      withAnimation(.spring(duration: 0.3)) {
        model.value = successToast
      }
      announceToAccessibility(successToast.message)
      return value
    } catch {
      let failureToast = onFailure(error)
      withAnimation(.spring(duration: 0.3)) {
        model.value = failureToast
      }
      announceToAccessibility(failureToast.message)
      throw error
    }
  }
}

internal let removalAnimationDuration: Double = 0.3
/// After an expanded message is collapsed, the toast dismisses this long after.
internal let collapsedMessageDismissDelay: TimeInterval = 2
/// Duration of the circle ⇄ capsule morph.
internal let morphAnimationDuration: Double = 0.35
internal let morphAnimation: Animation = .spring(duration: morphAnimationDuration, bounce: 0.2)
