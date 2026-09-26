import SwiftUI
import Toasts

/// One-tap presets that cover every `ToastValue` variation and the loading API.
struct CatalogView: View {
  @Environment(\.presentToast) private var presentToast

  var body: some View {
    NavigationStack {
      List {
        kindSection
        contentSection
        buttonSection
        durationSection
        loadingSection
        stackingSection
      }
      .navigationTitle("Catalog")
      .labScreen()
    }
  }

  // MARK: - Kinds

  private var kindSection: some View {
    Section {
      DemoRow(title: "Info", detail: "Soft impact", systemImage: "info.circle") {
        presentToast(
          ToastValue(icon: Image(systemName: "info.circle"), message: "A new version is available.", kind: .info))
      }
      DemoRow(title: "Success", detail: "Success notification", systemImage: "checkmark.circle") {
        presentToast(
          ToastValue(
            icon: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green),
            message: "Payment sent",
            kind: .success
          ))
      }
      DemoRow(title: "Warning", detail: "Warning notification", systemImage: "exclamationmark.triangle") {
        presentToast(
          ToastValue(
            icon: Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange),
            message: "Storage almost full",
            kind: .warning
          ))
      }
      DemoRow(title: "Error", detail: "Error notification", systemImage: "xmark.octagon") {
        presentToast(
          ToastValue(
            icon: Image(systemName: "xmark.octagon.fill").foregroundStyle(.red),
            message: "Couldn't send message",
            kind: .error,
            button: ToastButton(title: "Retry", color: .red) {}
          ))
      }
    } header: {
      Text("Kinds")
    } footer: {
      Text("Each kind plays its system haptic as the toast expands. Loading toasts play their result's.")
    }
  }

  // MARK: - Content

  private var contentSection: some View {
    Section {
      DemoRow(title: "Message only", detail: "No icon, no button", systemImage: "text.alignleft") {
        presentToast(ToastValue(message: "Message only toast."))
      }
      DemoRow(title: "SF Symbol icon", systemImage: "bell") {
        presentToast(
          ToastValue(icon: Image(systemName: "bell"), message: "You have a new notification."))
      }
      DemoRow(title: "Tinted icon", detail: "Icon keeps its own styling", systemImage: "paintpalette") {
        presentToast(
          ToastValue(
            icon: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green),
            message: "Saved",
            kind: .success
          ))
      }
      DemoRow(title: "Emoji icon", detail: "Text as the icon view", systemImage: "face.smiling") {
        presentToast(ToastValue(icon: Text("🎉"), message: "You reached 1,000 steps!"))
      }
      DemoRow(title: "Animated custom icon", detail: "Any View works", systemImage: "circle.dotted") {
        presentToast(ToastValue(icon: PulsingDot(), message: "Recording…"))
      }
      DemoRow(title: "Gradient icon", systemImage: "star.circle") {
        presentToast(ToastValue(icon: GradientBadge(), message: "Added to favorites"))
      }
      DemoRow(title: "Long message", detail: "Single line, tail truncation", systemImage: "text.word.spacing") {
        presentToast(
          ToastValue(
            icon: Image(systemName: "doc.text"),
            message:
              "This is a very long toast message that will certainly not fit on a single line of the screen."
          ))
      }
      DemoRow(title: "Arabic message", detail: "Right-to-left text", systemImage: "character.bubble") {
        presentToast(
          ToastValue(
            icon: Image(systemName: "checkmark.circle"),
            message: "تم حفظ التغييرات بنجاح",
            kind: .success
          ))
      }
    } header: {
      Text("Content")
    }
  }

  // MARK: - Buttons

  private var buttonSection: some View {
    Section {
      DemoRow(title: "Default button", detail: "Color defaults to .primary", systemImage: "button.horizontal") {
        presentToast(
          ToastValue(
            icon: Image(systemName: "wifi.exclamationmark"),
            message: "You're offline.",
            kind: .warning,
            button: ToastButton(title: "Retry") {
              presentToast(ToastValue(icon: Image(systemName: "wifi"), message: "Back online", kind: .success))
            }
          ))
      }
      DemoRow(title: "Undo button", detail: "Colored, triggers a follow-up toast", systemImage: "arrow.uturn.backward") {
        presentToast(
          ToastValue(
            icon: Image(systemName: "trash"),
            message: "Message deleted",
            button: ToastButton(title: "Undo", color: .red) {
              presentToast(
                ToastValue(icon: Image(systemName: "arrow.uturn.backward"), message: "Restored", kind: .success))
            }
          ))
      }
      DemoRow(title: "Button without icon", systemImage: "rectangle.dashed") {
        presentToast(
          ToastValue(
            message: "Toast with action required.",
            button: ToastButton(title: "Confirm", color: .green) {}
          ))
      }
      DemoRow(title: "Long button title", detail: "Button never truncates; message does", systemImage: "arrow.left.and.right") {
        presentToast(
          ToastValue(
            icon: Image(systemName: "icloud.and.arrow.up"),
            message: "Upload finished",
            button: ToastButton(title: "Open in Files", color: .blue) {}
          ))
      }
    } header: {
      Text("Buttons")
    } footer: {
      Text("Tapping a button runs its action but does not dismiss the toast.")
    }
  }

  // MARK: - Duration

  private var durationSection: some View {
    Section {
      durationRow(0, detail: "Removed almost immediately")
      durationRow(1)
      durationRow(3, detail: "The default")
      durationRow(10, detail: "The maximum")
      durationRow(30, detail: "Clamped to 10 s")
      durationRow(-5, detail: "Clamped to 0 s")
    } header: {
      Text("Duration")
    } footer: {
      Text("Swipe a toast toward the edge to dismiss it early. Dragging pauses the timer.")
    }
  }

  private func durationRow(_ seconds: TimeInterval, detail: String? = nil) -> some View {
    DemoRow(title: "\(Int(seconds)) seconds", detail: detail, systemImage: "timer") {
      presentToast(
        ToastValue(
          icon: Image(systemName: "timer"),
          message: "duration: \(Int(seconds))",
          duration: seconds
        ))
    }
  }

  // MARK: - Loading

  private var loadingSection: some View {
    Section {
      DemoRow(title: "Succeeds", detail: "1.5 s, then success toast", systemImage: "checkmark.circle") {
        Task {
          try? await presentToast(
            message: "Saving…",
            task: { try await simulateWork(seconds: 1.5, returning: "Saved") },
            onSuccess: { ToastValue(icon: Image(systemName: "checkmark.circle"), message: $0, kind: .success) },
            onFailure: { ToastValue(icon: Image(systemName: "xmark.circle"), message: $0.localizedDescription, kind: .error) }
          )
        }
      }
      DemoRow(title: "Fails", detail: "1.5 s, then failure toast", systemImage: "xmark.circle") {
        Task {
          try? await presentToast(
            message: "Syncing…",
            task: { try await simulateWork(seconds: 1.5, returning: "Synced", fails: true) },
            onSuccess: { ToastValue(icon: Image(systemName: "checkmark.circle"), message: $0, kind: .success) },
            onFailure: {
              ToastValue(
                icon: Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange),
                message: $0.localizedDescription,
                kind: .error
              )
            }
          )
        }
      }
      DemoRow(title: "Slow (6 s)", detail: "Loading toasts can't be swiped away", systemImage: "tortoise") {
        Task {
          try? await presentToast(
            message: "Uploading large file…",
            task: { try await simulateWork(seconds: 6, returning: ()) },
            onSuccess: { ToastValue(icon: Image(systemName: "icloud.and.arrow.up"), message: "Uploaded", kind: .success) },
            onFailure: { ToastValue(icon: Image(systemName: "xmark.circle"), message: $0.localizedDescription, kind: .error) }
          )
        }
      }
      DemoRow(title: "Success with button", detail: "Result toast can carry an action", systemImage: "square.and.arrow.down") {
        Task {
          try? await presentToast(
            message: "Downloading…",
            task: { try await simulateWork(seconds: 1.5, returning: "report.pdf") },
            onSuccess: { name in
              ToastValue(
                icon: Image(systemName: "doc.fill"),
                message: name,
                button: ToastButton(title: "Open", color: .blue) {}
              )
            },
            onFailure: { ToastValue(icon: Image(systemName: "xmark.circle"), message: $0.localizedDescription, kind: .error) }
          )
        }
      }
      DemoRow(title: "Use returned value", detail: "The call returns the task's result", systemImage: "arrow.turn.down.right") {
        Task {
          do {
            let count = try await presentToast(
              message: "Counting…",
              task: { try await simulateWork(seconds: 1, returning: 42) },
              onSuccess: { ToastValue(icon: Image(systemName: "number"), message: "Counted \($0) items") },
              onFailure: { ToastValue(icon: Image(systemName: "xmark.circle"), message: $0.localizedDescription, kind: .error) }
            )
            presentToast(ToastValue(message: "Caller received: \(count)"))
          } catch {
            // The failure toast already reports the error.
          }
        }
      }
      DemoRow(title: "Cancelled", detail: "Cancel the caller's Task after 1 s", systemImage: "stop.circle") {
        let task = Task {
          try? await presentToast(
            message: "Working…",
            task: { try await simulateWork(seconds: 5, returning: ()) },
            onSuccess: { ToastValue(icon: Image(systemName: "checkmark.circle"), message: "Done", kind: .success) },
            onFailure: { error in
              ToastValue(
                icon: Image(systemName: "stop.circle"),
                message: error is CancellationError ? "Cancelled" : error.localizedDescription
              )
            }
          )
        }
        Task {
          try? await Task.sleep(for: .seconds(1))
          task.cancel()
        }
      }
    } header: {
      Text("Loading (async)")
    }
  }

  // MARK: - Stacking

  private var stackingSection: some View {
    Section {
      DemoRow(title: "Burst of 3", detail: "Staggered by 0.2 s", systemImage: "square.stack.3d.up") {
        Task {
          for index in 1...3 {
            presentToast(
              ToastValue(icon: Image(systemName: "\(index).circle"), message: "Toast number \(index)"))
            try? await Task.sleep(for: .seconds(0.2))
          }
        }
      }
      DemoRow(title: "Burst of 6 at once", detail: "No limit on stack size", systemImage: "square.stack") {
        for index in 1...6 {
          presentToast(
            ToastValue(icon: Image(systemName: "\(index).square"), message: "Toast number \(index)"))
        }
      }
      DemoRow(title: "Mixed durations", detail: "1 s, 3 s and 6 s", systemImage: "hourglass") {
        for seconds in [6.0, 3.0, 1.0] {
          presentToast(
            ToastValue(
              icon: Image(systemName: "hourglass"),
              message: "Lives for \(Int(seconds)) s",
              duration: seconds
            ))
        }
      }
      DemoRow(title: "Loading and regular together", systemImage: "square.2.layers.3d") {
        presentToast(ToastValue(icon: Image(systemName: "bell"), message: "Regular toast"))
        Task {
          try? await presentToast(
            message: "Loading in parallel…",
            task: { try await simulateWork(seconds: 2, returning: ()) },
            onSuccess: { ToastValue(icon: Image(systemName: "checkmark.circle"), message: "Parallel done", kind: .success) },
            onFailure: { ToastValue(icon: Image(systemName: "xmark.circle"), message: $0.localizedDescription, kind: .error) }
          )
        }
      }
    } header: {
      Text("Stacking")
    }
  }
}
