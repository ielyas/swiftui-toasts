import SwiftUI
import Toasts

@main
struct ToastsLabApp: App {
  @State private var settings = LabSettings()

  var body: some Scene {
    WindowGroup {
      RootView()
        .environment(settings)
    }
  }
}

struct RootView: View {
  @Environment(LabSettings.self) private var settings

  var body: some View {
    Group {
      if LaunchOptions.isShowcase {
        // A blank screen, so recordings show only the toasts.
        Color(.systemBackground).ignoresSafeArea()
      } else {
        tabs
      }
    }
    .modifier(AutoplayModifier())
    .installToast(position: settings.position)
    .preferredColorScheme(LaunchOptions.colorScheme ?? settings.appearance.colorScheme)
    .environment(\.layoutDirection, settings.rightToLeft ? .rightToLeft : .leftToRight)
    .dynamicTypeSize(settings.dynamicTypeSize)
  }

  private var tabs: some View {
    TabView {
      Tab("Catalog", systemImage: "square.grid.2x2") {
        CatalogView()
      }
      Tab("Builder", systemImage: "slider.horizontal.3") {
        BuilderView()
      }
      Tab("Contexts", systemImage: "rectangle.stack") {
        ContextsView()
      }
      Tab("Settings", systemImage: "gearshape") {
        SettingsView()
      }
    }
  }
}

/// Launch arguments for recording the README media:
/// - `-autoplay` presents a sample of every toast shape without tapping.
/// - `-showcase` does the same over a blank screen.
/// - `-light` / `-dark` force the appearance.
private enum LaunchOptions {
  static let arguments = ProcessInfo.processInfo.arguments
  static let isShowcase = arguments.contains("-showcase")
  static let isAutoplay = isShowcase || arguments.contains("-autoplay")
  static let colorScheme: ColorScheme? =
    arguments.contains("-dark") ? .dark : arguments.contains("-light") ? .light : nil
}

/// Presents a sample of every toast shape when launched with `-autoplay` or `-showcase`,
/// e.g. `xcrun simctl launch <device> <bundle-id> -autoplay`.
private struct AutoplayModifier: ViewModifier {
  @Environment(\.presentToast) private var presentToast

  func body(content: Content) -> some View {
    content.task {
      guard LaunchOptions.isAutoplay else { return }
      try? await Task.sleep(for: .seconds(1))
      presentToast(ToastValue(message: "Message only", duration: 10))
      presentToast(
        ToastValue(
          icon: Image(systemName: "doc.text"),
          message: "This is a very long toast message that will certainly not fit on a single line of the screen.",
          showsDismissButton: true,
          duration: 10
        ))
      presentToast(ToastValue(icon: Image(systemName: "bell"), message: "You have a new notification.", duration: 10))
      presentToast(
        ToastValue(
          icon: Image(systemName: "trash"),
          message: "Message deleted",
          button: ToastButton(title: "Undo", color: .red) {},
          duration: 10
        ))
      try? await presentToast(
        message: "Uploading…",
        task: { try await simulateWork(seconds: 2, returning: ()) },
        onSuccess: {
          ToastValue(
            icon: Image(systemName: "checkmark.circle"),
            message: "Uploaded",
            kind: .success,
            button: ToastButton(title: "View", color: .blue) {},
            duration: 10
          )
        },
        onFailure: { ToastValue(message: $0.localizedDescription) }
      )
    }
  }
}
