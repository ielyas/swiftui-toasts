import SwiftUI
import Toasts

/// Compose a toast from individual parts and present it.
struct BuilderView: View {
  @Environment(\.presentToast) private var presentToast

  @State private var iconKind: IconKind = .symbol
  @State private var symbolName = "bell"
  @State private var iconTint: Color = .primary
  @State private var message = String(localized: "Hello from the builder")
  @State private var kind: ToastKind = .info
  @State private var hasButton = false
  @State private var showsDismissButton = false
  @State private var buttonTitle = String(localized: "Undo")
  @State private var buttonColor: Color = .red
  @State private var duration: Double = 3
  @State private var isLoading = false
  @State private var loadingSeconds: Double = 2
  @State private var loadingFails = false

  private let symbols = [
    "bell", "heart.fill", "star.fill", "trash", "paperplane.fill", "wifi.slash",
    "checkmark.circle", "xmark.circle", "exclamationmark.triangle",
  ]

  var body: some View {
    NavigationStack {
      Form {
        iconSection
        Section("Message") {
          TextField("Message", text: $message)
        }
        Section {
          Picker("Kind", selection: $kind) {
            ForEach(ToastKind.allCases, id: \.self) { Text($0.title).tag($0) }
          }
          .pickerStyle(.segmented)
        } header: {
          Text("Kind")
        } footer: {
          Text("Decides the haptic played as the toast appears.")
        }
        buttonSection
        dismissSection
        durationSection
        loadingSection
        Section {
          Button("Present", action: present)
            .frame(maxWidth: .infinity)
            .bold()
          Button("Present 3 times") {
            for _ in 0..<3 { present() }
          }
          .frame(maxWidth: .infinity)
        }
      }
      .navigationTitle("Builder")
      .labScreen()
    }
  }

  private var iconSection: some View {
    Section("Icon") {
      Picker("Kind", selection: $iconKind) {
        ForEach(IconKind.allCases) { Text($0.title).tag($0) }
      }
      .pickerStyle(.segmented)
      if iconKind == .symbol {
        Picker("Symbol", selection: $symbolName) {
          ForEach(symbols, id: \.self) { name in
            Label { Text(verbatim: name) } icon: { Image(systemName: name) }.tag(name)
          }
        }
        ColorPicker("Tint", selection: $iconTint)
      }
    }
  }

  private var buttonSection: some View {
    Section("Button") {
      Toggle("Show button", isOn: $hasButton)
      if hasButton {
        TextField("Title", text: $buttonTitle)
        ColorPicker("Color", selection: $buttonColor)
      }
    }
  }

  private var dismissSection: some View {
    Section("Dismissing") {
      Toggle("Close button", isOn: $showsDismissButton)
    }
  }

  private var durationSection: some View {
    Section {
      Slider(value: $duration, in: 0...15, step: 0.5) {
        Text("Duration")
      } minimumValueLabel: {
        Text(verbatim: "0")
      } maximumValueLabel: {
        Text(verbatim: "15")
      }
      LabeledContent("Requested", value: String(localized: "\(duration.formatted()) s"))
      LabeledContent("Effective", value: String(localized: "\(min(duration, 10).formatted()) s"))
    } header: {
      Text("Duration")
    } footer: {
      Text("Values above 10 s are clamped by the library.")
    }
    .disabled(isLoading)
  }

  private var loadingSection: some View {
    Section {
      Toggle("Wrap in loading task", isOn: $isLoading)
      if isLoading {
        Stepper("Task takes \(loadingSeconds.formatted()) s", value: $loadingSeconds, in: 0.5...10, step: 0.5)
        Toggle("Task throws", isOn: $loadingFails)
      }
    } header: {
      Text("Loading")
    } footer: {
      Text("When enabled, the message shows with a spinner, then the composed toast replaces it.")
    }
  }

  private var icon: (any View)? {
    switch iconKind {
    case .none: nil
    case .symbol: Image(systemName: symbolName).foregroundStyle(iconTint)
    case .emoji: Text(verbatim: "🔥")
    case .custom: PulsingDot(color: iconTint == .primary ? .red : iconTint)
    }
  }

  private var button: ToastButton? {
    guard hasButton else { return nil }
    return ToastButton(title: buttonTitle, color: buttonColor) {
      presentToast(ToastValue(message: String(localized: "Tapped \"\(buttonTitle)\"")))
    }
  }

  private func present() {
    let toast = ToastValue(icon: icon, message: message, kind: kind, button: button, showsDismissButton: showsDismissButton, duration: duration)
    guard isLoading else {
      presentToast(toast)
      return
    }
    let seconds = loadingSeconds
    let fails = loadingFails
    Task {
      try? await presentToast(
        message: message,
        task: { try await simulateWork(seconds: seconds, returning: (), fails: fails) },
        onSuccess: { toast },
        onFailure: { ToastValue(icon: Image(systemName: "xmark.circle"), message: $0.localizedDescription, kind: .error) }
      )
    }
  }
}

private enum IconKind: CaseIterable, Identifiable {
  case none, symbol, emoji, custom

  var id: Self { self }

  var title: LocalizedStringKey {
    switch self {
    case .none: "None"
    case .symbol: "Symbol"
    case .emoji: "Emoji"
    case .custom: "Custom"
    }
  }
}

extension ToastKind {
  fileprivate var title: LocalizedStringKey {
    switch self {
    case .info: "Info"
    case .success: "Success"
    case .warning: "Warning"
    case .error: "Error"
    }
  }
}
