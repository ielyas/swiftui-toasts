#if os(macOS)
import AppKit
import SwiftUI

/// Floats the toasts over their window in a borderless panel attached as a child window, so they
/// move and resize with it and show over its sheets.
///
/// The panel never becomes key or main, so presenting a toast never takes focus from the window.
/// Clicks pass through to the window everywhere except on a toast: the panel ignores mouse events
/// until the pointer is over a toast's frame, as each toast reports it to the manager.
internal final class ToastPanel: NSPanel {
  init() {
    super.init(
      contentRect: .zero,
      styleMask: [.borderless, .nonactivatingPanel],
      backing: .buffered,
      defer: true
    )
    isOpaque = false
    backgroundColor = .clear
    hasShadow = false
    level = .floating
    becomesKeyOnlyIfNeeded = true
    isReleasedWhenClosed = false
    animationBehavior = .none
    collectionBehavior = [.fullScreenAuxiliary, .ignoresCycle]
    ignoresMouseEvents = true
  }

  override var canBecomeKey: Bool { false }
  override var canBecomeMain: Bool { false }
}

/// Hosts the toasts in the panel, and takes a click only where a toast is.
internal final class ToastHostingView<Content: View>: NSHostingView<Content> {
  weak var manager: ToastManager?

  required init(rootView: Content) {
    super.init(rootView: rootView)
    // The panel's frame follows its window; the toasts never size it.
    sizingOptions = []
  }

  @MainActor required dynamic init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func hitTest(_ point: NSPoint) -> NSView? {
    guard let manager, manager.containsToast(at: toastPoint(fromSuperview: point)) else {
      return nil
    }
    return super.hitTest(point)
  }

  /// A point in SwiftUI's global space, which has its origin at the top leading corner.
  func toastPoint(fromWindow point: NSPoint) -> CGPoint {
    flipped(convert(point, from: nil))
  }

  private func toastPoint(fromSuperview point: NSPoint) -> CGPoint {
    flipped(convert(point, from: superview))
  }

  private func flipped(_ point: NSPoint) -> CGPoint {
    isFlipped ? point : CGPoint(x: point.x, y: bounds.height - point.y)
  }
}

/// Receives the pointer's movement over the window and the panel, from tracking areas it owns.
private final class ToastMouseTracker: NSResponder {
  var onMove: () -> Void = {}

  override func mouseMoved(with event: NSEvent) { onMove() }
  override func mouseEntered(with event: NSEvent) { onMove() }
  override func mouseExited(with event: NSEvent) { onMove() }
}

/// Bridges SwiftUI content into a `ToastPanel` attached to the window of the view it's placed in.
internal struct ToastWindowPresenter<Content: View>: NSViewRepresentable {
  let manager: ToastManager
  let isPresented: Bool
  let content: Content

  func makeNSView(context: Context) -> HostView {
    HostView(manager: manager)
  }

  func updateNSView(_ view: HostView, context: Context) {
    view.update(
      isPresented: isPresented,
      content: EnvironmentPassingView(content: content, environment: context.environment)
    )
  }

  static func dismantleNSView(_ view: HostView, coordinator: ()) {
    view.detach()
  }

  /// Carries the presenting view's environment (color scheme, layout direction, Dynamic Type…)
  /// into the toast panel, which otherwise wouldn't inherit it.
  struct EnvironmentPassingView: View {
    let content: Content
    let environment: EnvironmentValues

    var body: some View {
      content
        .environment(\.self, environment)
        // Fills the panel, so the toasts center in the window rather than the panel shrinking to them.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }

  final class HostView: NSView {
    private let manager: ToastManager
    private weak var hostWindow: NSWindow?
    private var panel: ToastPanel?
    private var hostingView: ToastHostingView<EnvironmentPassingView>?
    private var isPresented = false
    private var content: EnvironmentPassingView?
    private var windowObservers: [NSObjectProtocol] = []
    private let mouseTracker = ToastMouseTracker()
    private var panelTrackingArea: NSTrackingArea?

    init(manager: ToastManager) {
      self.manager = manager
      super.init(frame: .zero)
      mouseTracker.onMove = { [weak self] in self?.updateMouseEvents() }
      // Follows the pointer over the window, so the panel starts taking clicks on a toast.
      addTrackingArea(Self.trackingArea(owner: mouseTracker))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func viewDidMoveToWindow() {
      super.viewDidMoveToWindow()
      guard window !== hostWindow else { return }
      detach()
      guard let window else { return }
      hostWindow = window
      observe(window)
      apply()
    }

    func update(isPresented: Bool, content: EnvironmentPassingView) {
      self.isPresented = isPresented
      self.content = content
      apply()
    }

    /// Removes the panel and stops following the window.
    func detach() {
      hidePanel()
      for observer in windowObservers {
        NotificationCenter.default.removeObserver(observer)
      }
      windowObservers = []
      hostWindow = nil
    }

    private func observe(_ window: NSWindow) {
      let layoutNames: [Notification.Name] = [
        NSWindow.didResizeNotification,
        NSWindow.didMoveNotification,
        NSWindow.didEnterFullScreenNotification,
        NSWindow.didExitFullScreenNotification,
      ]
      windowObservers = layoutNames.map { name in
        NotificationCenter.default.addObserver(forName: name, object: window, queue: .main) {
          [weak self] _ in
          MainActor.assumeIsolated { self?.layoutPanel() }
        }
      }
      windowObservers.append(
        NotificationCenter.default.addObserver(
          forName: NSWindow.willCloseNotification, object: window, queue: .main
        ) { [weak self] _ in
          MainActor.assumeIsolated { self?.hidePanel() }
        })
    }

    private func apply() {
      guard let hostWindow, let content else { return }
      guard isPresented else {
        hidePanel()
        return
      }
      let panel = self.panel ?? ToastPanel()
      self.panel = panel
      if let hostingView {
        hostingView.rootView = content
      } else {
        let hostingView = ToastHostingView(rootView: content)
        hostingView.manager = manager
        let trackingArea = Self.trackingArea(owner: mouseTracker)
        hostingView.addTrackingArea(trackingArea)
        panelTrackingArea = trackingArea
        // A plain container is the panel's content view, with the hosting view filling it. As the
        // content view itself, the hosting view would size the panel to the toasts' own width.
        let container = NSView()
        hostingView.frame = container.bounds
        hostingView.autoresizingMask = [.width, .height]
        container.addSubview(hostingView)
        panel.contentView = container
        self.hostingView = hostingView
      }
      layoutPanel()
      if panel.parent !== hostWindow {
        panel.parent?.removeChildWindow(panel)
        hostWindow.addChildWindow(panel, ordered: .above)
      }
      updateMouseEvents()
    }

    /// Keeps the panel over the window's content, below its toolbar.
    private func layoutPanel() {
      guard let hostWindow, let panel else { return }
      let frame = hostWindow.convertToScreen(hostWindow.contentLayoutRect)
      if panel.frame != frame {
        panel.setFrame(frame, display: true)
      }
    }

    private func hidePanel() {
      guard let panel else { return }
      panel.parent?.removeChildWindow(panel)
      panel.orderOut(nil)
      if let panelTrackingArea {
        hostingView?.removeTrackingArea(panelTrackingArea)
      }
      panelTrackingArea = nil
      panel.contentView = nil
      hostingView = nil
      self.panel = nil
    }

    /// The panel takes the mouse only while the pointer is over a toast.
    private func updateMouseEvents() {
      guard let panel, let hostingView else { return }
      let windowPoint = panel.convertPoint(fromScreen: NSEvent.mouseLocation)
      let isOverToast = manager.containsToast(at: hostingView.toastPoint(fromWindow: windowPoint))
      if panel.ignoresMouseEvents == isOverToast {
        panel.ignoresMouseEvents = !isOverToast
      }
    }

    private static func trackingArea(owner: NSResponder) -> NSTrackingArea {
      NSTrackingArea(
        rect: .zero,
        options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect],
        owner: owner
      )
    }
  }
}
#endif
