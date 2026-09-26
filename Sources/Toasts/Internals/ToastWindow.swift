import SwiftUI
import UIKit

/// Hosts the toasts in their own window above the app, so they show over sheets and covers.
///
/// Touches pass through to the app everywhere except on a toast. Liquid Glass is composited by the
/// system, so the window can't tell a toast from empty space by sampling its pixels; instead each
/// toast reports its frame to the manager, and only points inside those frames are hit.
internal final class ToastWindow: UIWindow {
  weak var manager: ToastManager?

  override init(windowScene: UIWindowScene) {
    super.init(windowScene: windowScene)
    windowLevel = .alert
    backgroundColor = .clear
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    guard let manager, manager.containsToast(at: point) else { return nil }
    return super.hitTest(point, with: event)
  }
}

/// Bridges SwiftUI content into a `ToastWindow` attached to the scene of the view it's placed in.
internal struct ToastWindowPresenter<Content: View>: UIViewRepresentable {
  let manager: ToastManager
  let isPresented: Bool
  let content: Content

  func makeUIView(context: Context) -> HostView {
    HostView(manager: manager)
  }

  func updateUIView(_ view: HostView, context: Context) {
    view.update(
      isPresented: isPresented,
      content: EnvironmentPassingView(content: content, environment: context.environment)
    )
  }

  /// Carries the presenting view's environment (color scheme, layout direction, Dynamic Type…)
  /// into the toast window, which otherwise wouldn't inherit it.
  struct EnvironmentPassingView: View {
    let content: Content
    let environment: EnvironmentValues

    var body: some View {
      content.environment(\.self, environment)
    }
  }

  final class HostView: UIView {
    private let manager: ToastManager
    private var toastWindow: ToastWindow?
    private var isPresented = false
    private var content: EnvironmentPassingView?

    init(manager: ToastManager) {
      self.manager = manager
      super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func willMove(toWindow newWindow: UIWindow?) {
      super.willMove(toWindow: newWindow)
      guard let windowScene = newWindow?.windowScene else {
        toastWindow?.isHidden = true
        toastWindow = nil
        return
      }
      guard toastWindow?.windowScene !== windowScene else { return }
      let window = ToastWindow(windowScene: windowScene)
      window.manager = manager
      toastWindow = window
      apply()
    }

    func update(isPresented: Bool, content: EnvironmentPassingView) {
      self.isPresented = isPresented
      self.content = content
      apply()
    }

    private func apply() {
      guard let toastWindow, let content else { return }
      guard isPresented else {
        toastWindow.rootViewController = nil
        toastWindow.isHidden = true
        return
      }
      if let hostingController = toastWindow.rootViewController
        as? UIHostingController<EnvironmentPassingView>
      {
        hostingController.rootView = content
      } else {
        let hostingController = UIHostingController(rootView: content)
        hostingController.view.backgroundColor = .clear
        hostingController.safeAreaRegions = []
        toastWindow.rootViewController = hostingController
      }
      toastWindow.isHidden = false
    }
  }
}
