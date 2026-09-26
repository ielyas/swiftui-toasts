import SwiftUI

internal struct LoadingView: View {
  var body: some View {
    ProgressView()
      .controlSize(.small)
  }
}

#Preview {
  LoadingView()
}
