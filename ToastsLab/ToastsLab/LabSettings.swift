import SwiftUI
import Toasts

/// App-wide knobs that change how toasts are installed and rendered.
@MainActor
@Observable
final class LabSettings {
  var position: ToastPosition = .bottom
  var appearance: Appearance = .system
  var rightToLeft = false
  var dynamicTypeSize: DynamicTypeSize = .large
  var showsTabBar = true
  var observesSafeArea = true
}

enum Appearance: String, CaseIterable, Identifiable {
  case system, light, dark

  var id: Self { self }

  var colorScheme: ColorScheme? {
    switch self {
    case .system: nil
    case .light: .light
    case .dark: .dark
    }
  }
}

extension View {
  /// Applies the per-screen settings: tab bar visibility and the toast safe-area observer.
  func labScreen() -> some View {
    modifier(LabScreenModifier())
  }
}

private struct LabScreenModifier: ViewModifier {
  @Environment(LabSettings.self) private var settings

  func body(content: Content) -> some View {
    Group {
      if settings.observesSafeArea {
        content.addToastSafeAreaObserver()
      } else {
        content
      }
    }
    .toolbarVisibility(settings.showsTabBar ? .visible : .hidden, for: .tabBar)
  }
}
