import SwiftUI
import Toasts

/// Colorful, scrollable content to judge how the Liquid Glass toasts blur and reflect what's behind them.
struct GlassBackdropView: View {
  @Environment(\.presentToast) private var presentToast

  private let symbols = [
    "sun.max.fill", "moon.stars.fill", "cloud.bolt.fill", "leaf.fill", "flame.fill", "drop.fill",
    "bolt.fill", "snowflake", "sparkles", "tornado", "rainbow", "wind",
  ]
  private let colors: [Color] = [.red, .orange, .yellow, .green, .mint, .teal, .cyan, .blue, .indigo, .purple, .pink]

  var body: some View {
    ScrollView {
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
        ForEach(0..<60, id: \.self) { index in
          let color = colors[index % colors.count]
          RoundedRectangle(cornerRadius: 20)
            .fill(color.gradient)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
              Image(systemName: symbols[index % symbols.count])
                .font(.largeTitle)
                .foregroundStyle(.white)
            }
        }
      }
      .padding()
    }
    .navigationTitle("Glass backdrop")
    .toolbar {
      ToolbarItem(placement: .bottomBar) {
        Button("Toast", systemImage: "bell") {
          presentToast(ToastValue(icon: Image(systemName: "bell"), message: "Glass over color"))
        }
      }
      ToolbarItem(placement: .bottomBar) {
        Button("With button", systemImage: "button.horizontal") {
          presentToast(
            ToastValue(
              icon: Image(systemName: "trash"),
              message: "Photo deleted",
              button: ToastButton(title: "Undo", color: .red) {}
            ))
        }
      }
      ToolbarItem(placement: .bottomBar) {
        Button("Loading", systemImage: "arrow.triangle.2.circlepath") {
          Task {
            try? await presentToast(
              message: "Uploading…",
              task: { try await simulateWork(seconds: 2, returning: ()) },
              onSuccess: {
                ToastValue(
                  icon: Image(systemName: "checkmark.circle"),
                  message: "Uploaded",
                  kind: .success,
                  button: ToastButton(title: "View", color: .blue) {}
                )
              },
              onFailure: { ToastValue(icon: Image(systemName: "xmark.circle"), message: $0.localizedDescription, kind: .error) }
            )
          }
        }
      }
    }
    .labScreen()
  }
}
