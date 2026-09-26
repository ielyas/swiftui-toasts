import SwiftUI

/// A tappable list row with a title and a short explanation of what it tests.
struct DemoRow: View {
  let title: String
  var detail: String? = nil
  var systemImage: String = "sparkles"
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Label {
        VStack(alignment: .leading, spacing: 2) {
          Text(title)
            .foregroundStyle(Color(.label))
          if let detail {
            Text(detail)
              .font(.footnote)
              .foregroundStyle(Color(.secondaryLabel))
          }
        }
      } icon: {
        Image(systemName: systemImage)
      }
    }
  }
}

/// A custom, animated view used to prove that `ToastValue.icon` accepts any view.
struct PulsingDot: View {
  var color: Color = .red
  @State private var isPulsing = false

  var body: some View {
    ZStack {
      Circle()
        .fill(color.opacity(0.3))
        .scaleEffect(isPulsing ? 1.0 : 0.4)
      Circle()
        .fill(color)
        .frame(width: 8, height: 8)
    }
    .onAppear {
      withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
        isPulsing = true
      }
    }
  }
}

/// A gradient badge, another non-image icon.
struct GradientBadge: View {
  var body: some View {
    Circle()
      .fill(
        LinearGradient(
          colors: [.pink, .orange, .yellow],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
      .overlay {
        Image(systemName: "star.fill")
          .font(.system(size: 9, weight: .bold))
          .foregroundStyle(.white)
      }
  }
}

enum LabError: LocalizedError {
  case network

  var errorDescription: String? {
    switch self {
    case .network: "Network connection lost"
    }
  }
}

/// Simulated async work for loading toasts.
func simulateWork<V: Sendable>(
  seconds: Double,
  returning value: V,
  fails: Bool = false
) async throws -> V {
  try await Task.sleep(for: .seconds(seconds))
  if fails { throw LabError.network }
  return value
}
