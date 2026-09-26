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
    .modifier(AutoplayModifier())
    .installToast(position: settings.position)
    .preferredColorScheme(settings.appearance.colorScheme)
    .environment(\.layoutDirection, settings.rightToLeft ? .rightToLeft : .leftToRight)
    .dynamicTypeSize(settings.dynamicTypeSize)
  }
}

/// Launch with `-autoplay` to present a sample of every toast shape without tapping,
/// e.g. `xcrun simctl launch <device> sa.elyas.ToastsLab -autoplay`.
private struct AutoplayModifier: ViewModifier {
  @Environment(\.presentToast) private var presentToast

  func body(content: Content) -> some View {
    content.task {
      guard ProcessInfo.processInfo.arguments.contains("-autoplay") else { return }
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
