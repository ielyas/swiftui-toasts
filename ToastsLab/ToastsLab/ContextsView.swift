import SwiftUI
import Toasts

/// Presents toasts from different places in the view hierarchy.
struct ContextsView: View {
  @Environment(\.presentToast) private var presentToast
  @State private var showsSheet = false
  @State private var showsCover = false
  @State private var showsNestedInstall = false
  @State private var text = ""
  @FocusState private var isFieldFocused: Bool

  var body: some View {
    NavigationStack {
      List {
        Section {
          DemoRow(title: "From a sheet", detail: "The toast window sits above sheets", systemImage: "rectangle.bottomhalf.filled") {
            showsSheet = true
          }
          DemoRow(title: "From a full-screen cover", systemImage: "rectangle.inset.filled") {
            showsCover = true
          }
          NavigationLink {
            PushedView()
          } label: {
            Label("From a pushed screen", systemImage: "arrow.right.square")
          }
          NavigationLink {
            GlassBackdropView()
          } label: {
            Label("Glass backdrop", systemImage: "circle.hexagongrid")
          }
        } header: {
          Text("Presentation")
        }

        Section {
          TextField("Type, then press return", text: $text)
            .focused($isFieldFocused)
            .submitLabel(.send)
            .onSubmit {
              presentToast(
                ToastValue(
                  icon: Image(systemName: "keyboard"),
                  message: text.isEmpty ? String(localized: "Empty message") : text
                ))
              isFieldFocused = true
            }
        } header: {
          Text("Keyboard")
        } footer: {
          Text("With the safe-area observer on, bottom toasts should rise above the keyboard.")
        }

        Section {
          DemoRow(title: "Sheet with its own installToast", detail: "A second, independent toast host at the top", systemImage: "square.on.square") {
            showsNestedInstall = true
          }
        } header: {
          Text("Multiple hosts")
        }
      }
      .navigationTitle("Contexts")
      .labScreen()
    }
    .sheet(isPresented: $showsSheet) {
      ModalDemo(title: String(localized: "Sheet"))
        .presentationDetents([.medium, .large])
    }
    .fullScreenCover(isPresented: $showsCover) {
      ModalDemo(title: String(localized: "Full-screen cover"))
    }
    .sheet(isPresented: $showsNestedInstall) {
      ModalDemo(title: String(localized: "Nested host (top)"))
        .installToast(position: .top)
    }
  }
}

private struct ModalDemo: View {
  let title: String
  @Environment(\.presentToast) private var presentToast
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      List {
        DemoRow(title: "Present toast", systemImage: "bell") {
          presentToast(ToastValue(icon: Image(systemName: "bell"), message: String(localized: "Hello from \(title)")))
        }
        DemoRow(title: "Present, then dismiss", detail: "Toast outlives the modal", systemImage: "xmark.square") {
          presentToast(ToastValue(icon: Image(systemName: "checkmark.circle"), message: String(localized: "Closed \(title)"), kind: .success))
          dismiss()
        }
        DemoRow(title: "Loading, then dismiss", detail: "Task keeps running after the modal closes", systemImage: "arrow.triangle.2.circlepath") {
          Task {
            try? await presentToast(
              message: String(localized: "Saving…"),
              task: { try await simulateWork(seconds: 2, returning: ()) },
              onSuccess: { ToastValue(icon: Image(systemName: "checkmark.circle"), message: String(localized: "Saved"), kind: .success) },
              onFailure: { ToastValue(icon: Image(systemName: "xmark.circle"), message: $0.localizedDescription, kind: .error) }
            )
          }
          dismiss()
        }
      }
      .navigationTitle(title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        Button("Done") { dismiss() }
      }
    }
  }
}

private struct PushedView: View {
  @Environment(\.presentToast) private var presentToast

  var body: some View {
    List {
      DemoRow(title: "Present toast", systemImage: "bell") {
        presentToast(ToastValue(icon: Image(systemName: "bell"), message: String(localized: "Hello from a pushed screen")))
      }
    }
    .navigationTitle("Pushed")
    .labScreen()
  }
}
