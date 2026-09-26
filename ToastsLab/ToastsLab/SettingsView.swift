import SwiftUI
import Toasts

/// Global knobs: position, appearance, layout direction, text size and safe-area handling.
struct SettingsView: View {
  @Environment(LabSettings.self) private var settings
  @Environment(\.presentToast) private var presentToast

  var body: some View {
    @Bindable var settings = settings
    NavigationStack {
      Form {
        Section {
          Picker("Position", selection: $settings.position) {
            Text("Top").tag(ToastPosition.top)
            Text("Bottom").tag(ToastPosition.bottom)
          }
          .pickerStyle(.segmented)
        } header: {
          Text(verbatim: "installToast(position:)")
        } footer: {
          Text("Changing the position while toasts are visible moves them live.")
        }

        Section("Appearance") {
          Picker("Theme", selection: $settings.appearance) {
            ForEach(Appearance.allCases) { Text($0.title).tag($0) }
          }
          .pickerStyle(.segmented)
          Toggle("Right-to-left layout", isOn: $settings.rightToLeft)
          Picker("Text size", selection: $settings.dynamicTypeSize) {
            ForEach(DynamicTypeSize.allCases, id: \.self) { size in
              Text(verbatim: String(describing: size)).tag(size)
            }
          }
        }

        Section {
          Toggle("Show tab bar", isOn: $settings.showsTabBar)
          Toggle(isOn: $settings.observesSafeArea) {
            Text(verbatim: "addToastSafeAreaObserver()")
          }
        } header: {
          Text("Safe area")
        } footer: {
          Text(
            "The observer on each tab reports the tab bar inset, so bottom toasts avoid it. Top toasts ignore it. Turn it off to compare."
          )
        }

        Section {
          DemoRow(title: "Test toast", systemImage: "bell") {
            presentToast(
              ToastValue(
                icon: Image(systemName: "bell"),
                message: settings.position == .top
                  ? String(localized: "Position: top") : String(localized: "Position: bottom"),
                button: ToastButton(title: String(localized: "OK")) {}
              ))
          }
          DemoRow(title: "Toast, then flip position", detail: "Watch the stack move", systemImage: "arrow.up.arrow.down") {
            presentToast(ToastValue(icon: Image(systemName: "arrow.up.arrow.down"), message: String(localized: "Moving…"), duration: 5))
            Task {
              try? await Task.sleep(for: .seconds(1))
              settings.position = settings.position == .top ? .bottom : .top
            }
          }
        }
      }
      .navigationTitle("Settings")
      .labScreen()
    }
  }
}
