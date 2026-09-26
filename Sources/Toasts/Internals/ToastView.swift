import SwiftUI

/// A toast rendered as Liquid Glass.
///
/// It enters as a glass circle (showing the icon, if any) and, once in place, the same capsule
/// expands to reveal the message and button. Dismissal plays this in reverse.
///
/// The message and the optional action button are separate glass capsules rather than a button
/// nested inside the toast, so glass is never layered on glass. While hidden, the button is tucked
/// inside the message capsule; the toast's own `GlassEffectContainer` fuses the overlapping glass,
/// so the button visibly morphs out of the toast and back into it.
///
/// A message too long for one line shows a chevron, and tapping the toast expands it to show the
/// message in full.
internal struct ToastView: View {
  @ObservedObject var model: ToastModel
  @Namespace private var namespace
  /// The message's full one-line width, and the width it's actually given; the chevron shows only
  /// when the first exceeds the second.
  @State private var fullMessageWidth: CGFloat = 0
  @State private var shownMessageWidth: CGFloat = 0
  /// Taps as the message starts expanding or collapsing, and again as it settles.
  @State private var messageHaptic: MotionHaptic?
  @State private var messageSettleTask: Task<Void, Never>?

  private var isMessageTruncated: Bool { fullMessageWidth > shownMessageWidth + 1 }
  private var isMessageExpandable: Bool {
    model.isExpanded && (isMessageTruncated || model.isMessageExpanded)
  }

  @ScaledMetric(relativeTo: .callout) private var iconSize: CGFloat = 20
  @ScaledMetric(relativeTo: .callout) private var minHeight: CGFloat = 48
  private let buttonGap: CGFloat = 8

  /// A capsule on one line, a circle when collapsed, and a rounded rectangle when the message wraps.
  private var messageShape: RoundedRectangle {
    RoundedRectangle(cornerRadius: minHeight / 2, style: .circular)
  }

  var body: some View {
    // Container spacing matches the gap, so the glass stays fused while the button separates.
    GlassEffectContainer(spacing: buttonGap) {
      HStack(spacing: buttonGap) {
        message
        if let button = model.button {
          ToastButtonView(
            button: button,
            isExpanded: model.isExpanded,
            minHeight: minHeight,
            gap: buttonGap,
            namespace: namespace
          )
        }
      }
    }
    .font(.callout.weight(.medium))
    .sensoryFeedback(trigger: messageHaptic) { _, haptic in
      haptic?.sensoryFeedback
    }
  }

  private var message: some View {
    HStack(alignment: .top, spacing: 10) {
      if let icon = model.icon {
        icon
          .frame(width: iconSize, height: iconSize)
      }
      if model.isExpanded {
        messageText
          .id(model.message)
          .transition(
            .asymmetric(
              insertion: .opacity.animation(.spring(duration: 0.3).delay(0.15)),
              removal: .opacity.animation(.spring(duration: 0.15))
            ))
      }
    }
    // Collapsed, the capsule is a circle: no padding, and at least as wide as it is tall.
    .padding(.horizontal, model.isExpanded ? 16 : 0)
    .padding(.vertical, model.isMessageExpanded ? 14 : 0)
    .frame(minWidth: minHeight, minHeight: minHeight)
    // Keeps fading text from spilling outside the capsule while it shrinks.
    .clipShape(messageShape)
    // The whole toast, not just the chevron, expands and collapses the message.
    .contentShape(messageShape)
    .onTapGesture(perform: toggleMessageExpansion)
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(isMessageExpandable ? .isButton : [])
    .accessibilityHint(
      isMessageExpandable ? (model.isMessageExpanded ? "Shows less" : "Shows the full message") : ""
    )
    .accessibilityAction {
      toggleMessageExpansion()
    }
    .glassEffect(.regular.interactive(), in: messageShape)
    .glassEffectID(ToastGlassID.message, in: namespace)
    // A new toast appears in place rather than morphing out of other glass.
    .glassEffectTransition(.materialize)
  }

  @ViewBuilder
  private var messageText: some View {
    if model.isMessageExpanded {
      HStack(alignment: .top, spacing: 6) {
        Text(model.message)
          .fixedSize(horizontal: false, vertical: true)
          .frame(maxWidth: .infinity, alignment: .leading)
        messageExpansionIndicator
      }
    } else {
      HStack(spacing: 6) {
        Text(model.message)
          .lineLimit(1)
          .truncationMode(.tail)
          .onGeometryChange(for: CGFloat.self, of: \.size.width) { shownMessageWidth = $0 }
          .background(alignment: .leading) {
            Text(model.message)
              .lineLimit(1)
              .fixedSize()
              .hidden()
              .onGeometryChange(for: CGFloat.self, of: \.size.width) { fullMessageWidth = $0 }
          }
        // Only offer the chevron when the message doesn't fit on one line.
        if isMessageTruncated {
          messageExpansionIndicator
        }
      }
    }
  }

  /// A visual cue that the toast can be tapped to expand or collapse the message.
  private var messageExpansionIndicator: some View {
    Image(systemName: "chevron.down")
      .font(.footnote.weight(.semibold))
      .foregroundStyle(.secondary)
      .rotationEffect(.degrees(model.isMessageExpanded ? 180 : 0))
      .frame(width: iconSize, height: iconSize)
      .accessibilityHidden(true)
  }

  private func toggleMessageExpansion() {
    guard isMessageExpandable else { return }
    if model.isMessageExpanded {
      model.hasCollapsedMessage = true
    }
    withAnimation(morphAnimation) {
      model.isMessageExpanded.toggle()
    }
    messageHaptic = model.isMessageExpanded ? .entering : .leaving
    messageSettleTask?.cancel()
    messageSettleTask = Task {
      guard (try? await Task.sleep(for: .seconds(morphAnimationDuration))) != nil,
        !model.isDismissing
      else { return }
      messageHaptic = .settled
    }
  }
}

/// The action button's glass capsule. Hidden, it's a circle tucked inside the trailing end of the
/// message capsule; revealed, it slides out and widens to fit its title.
private struct ToastButtonView: View {
  let button: ToastButton
  let isExpanded: Bool
  let minHeight: CGFloat
  let gap: CGFloat
  let namespace: Namespace.ID

  /// False until first shown, so a button that arrives later (e.g. when a loading toast resolves)
  /// starts tucked in and morphs out rather than just appearing.
  @State private var hasAppeared = false

  private var isRevealed: Bool { isExpanded && hasAppeared }

  var body: some View {
    Button(action: button.action) {
      Text(button.title)
        .fixedSize()
        .foregroundStyle(button.color)
        .opacity(isRevealed ? 1 : 0)
        // The title shows once the button has moved clear of the toast, and hides before it tucks back in.
        .animation(isRevealed ? .easeOut(duration: 0.2).delay(0.15) : nil, value: isRevealed)
        .padding(.horizontal, isRevealed ? 16 : 0)
        .frame(width: isRevealed ? nil : minHeight)
        .frame(minHeight: minHeight)
        .contentShape(.capsule)
    }
    .buttonStyle(.plain)
    .clipShape(.capsule)
    .glassEffect(.regular.interactive(), in: .capsule)
    .glassEffectID(ToastGlassID.button, in: namespace)
    // Pulls the hidden button back over the message capsule's trailing end.
    .padding(.leading, isRevealed ? 0 : -(minHeight + gap))
    .allowsHitTesting(isRevealed)
    .accessibilityHidden(!isRevealed)
    .onAppear {
      withAnimation(morphAnimation) {
        hasAppeared = true
      }
    }
  }
}

private enum ToastGlassID: Hashable, Sendable {
  case message, button
}

#Preview {
  let toasts: [ToastValue] = [
    .init(
      icon: Image(systemName: "info.circle"),
      message: "This is a toast message",
      button: .init(title: "Action", color: .red, action: {})
    ),
    .init(
      icon: Image(systemName: "info.circle"),
      message: "This is a toast message",
      button: .init(title: "Action", action: {})
    ),
    .init(icon: Image(systemName: "info.circle"), message: "This is a toast message"),
    .init(message: "This is a toast message"),
    .init(message: "Copied"),
  ]
  ZStack {
    LinearGradient(colors: [.orange, .pink, .purple], startPoint: .top, endPoint: .bottom)
      .ignoresSafeArea()
    VStack(spacing: 8) {
      ForEach(toasts.indices, id: \.self) { index in
        ToastView(model: expandedModel(toasts[index]))
      }
    }
  }
}

@MainActor
private func expandedModel(_ value: ToastValue) -> ToastModel {
  let model = ToastModel(value: value)
  model.isExpanded = true
  return model
}
