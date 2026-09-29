import SwiftUI

/// A toast rendered as Liquid Glass.
///
/// It enters as a glass circle (showing the icon, if any) and, once in place, the same capsule
/// expands to reveal the message and button. Dismissal plays this in reverse.
///
/// The optional action button and close button sit inside the capsule as plain buttons rather than
/// glass of their own, so the toast is a single piece of glass and glass is never layered on glass.
///
/// A message too long for one line shows a chevron, and tapping the toast expands it to show the
/// message in full.
internal struct ToastView: View {
  @ObservedObject var model: ToastModel
  var onDismiss: () -> Void = {}
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

  /// The height of the action button's capsule and the close button's circle.
  @ScaledMetric(relativeTo: .callout) private var buttonHeight: CGFloat = 32
  /// How far a button sits from the toast's edge when it ends the toast; the same inset it has above
  /// and below on one line, so its shape is concentric with the toast's.
  private var buttonInset: CGFloat { (minHeight - buttonHeight) / 2 }
  private var endsWithButton: Bool {
    #if os(tvOS)
      false
    #else
      model.button != nil || model.showsDismissButton
    #endif
  }

  /// A capsule on one line, a circle when collapsed, and a rounded rectangle when the message wraps.
  private var messageShape: RoundedRectangle {
    RoundedRectangle(cornerRadius: minHeight / 2, style: .circular)
  }

  var body: some View {
    GlassEffectContainer {
      capsule
    }
    .font(.callout.weight(.medium))
    .sensoryFeedback(trigger: messageHaptic) { _, haptic in
      haptic?.sensoryFeedback
    }
  }

  private var capsule: some View {
    HStack(alignment: .top, spacing: 10) {
      message
      // On tvOS a toast is message-only: a button would have to take focus to be used.
      #if !os(tvOS)
        if model.isExpanded {
          if let button = model.button {
            actionButton(button)
              .transition(contentTransition)
          }
          if model.showsDismissButton {
            dismissButton
              .transition(contentTransition)
          }
        }
      #endif
    }
    // Collapsed, the capsule is a circle: no padding, and at least as wide as it is tall.
    .padding(.leading, model.isExpanded ? 16 : 0)
    .padding(.trailing, model.isExpanded ? (endsWithButton ? buttonInset : 16) : 0)
    .padding(.vertical, model.isMessageExpanded ? 14 : 0)
    .frame(minWidth: minHeight, minHeight: minHeight)
    // Keeps fading text from spilling outside the capsule while it shrinks.
    .clipShape(messageShape)
    #if os(tvOS)
      // A toast never takes focus on tvOS, so it has nothing to press and isn't interactive glass.
      .focusable(false)
      .glassEffect(.regular, in: messageShape)
    #else
      // The whole toast, not just the chevron, expands and collapses the message.
      .contentShape(messageShape)
      .onTapGesture(perform: toggleMessageExpansion)
      .glassEffect(.regular.interactive(), in: messageShape)
    #endif
    .glassEffectID(ToastGlassID.message, in: namespace)
    // A new toast appears in place rather than morphing out of other glass.
    .glassEffectTransition(.materialize)
  }

  /// The icon and message, which VoiceOver reads as one element that also expands the message
  /// and dismisses the toast.
  private var message: some View {
    HStack(alignment: .top, spacing: 10) {
      if let icon = model.icon {
        icon
          .frame(width: iconSize, height: iconSize)
      }
      if model.isExpanded {
        messageText
          .id(model.message)
          .transition(contentTransition)
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(isMessageExpandable ? .isButton : [])
    .accessibilityHint(messageHint)
    .accessibilityAction {
      toggleMessageExpansion()
    }
    .accessibilityActions {
      if model.showsDismissButton {
        Button(String(localized: "Dismiss", bundle: .module, comment: "VoiceOver action that dismisses the toast"), action: onDismiss)
      }
    }
    .accessibilityAction(.escape) {
      if model.showsDismissButton { onDismiss() }
    }
  }

  /// VoiceOver's hint for a message that can expand or collapse.
  private var messageHint: Text {
    guard isMessageExpandable else { return Text(verbatim: "") }
    return model.isMessageExpanded
      ? Text("Shows less", bundle: .module, comment: "VoiceOver hint for collapsing an expanded toast message")
      : Text("Shows the full message", bundle: .module, comment: "VoiceOver hint for expanding a truncated toast message")
  }

  /// Content fades in once the circle has started expanding, and out before it collapses.
  private var contentTransition: AnyTransition {
    .asymmetric(
      insertion: .opacity.animation(.spring(duration: 0.3).delay(0.15)),
      removal: .opacity.animation(.spring(duration: 0.15))
    )
  }

  /// The action button, a small capsule tinted with the button's color inside the toast — or,
  /// with a `systemImage`, a circle the size of the dismiss button. It's a translucent fill
  /// rather than glass, so glass is never layered on glass. Its title never truncates; the
  /// message gives way instead.
  private func actionButton(_ button: ToastButton) -> some View {
    Button(action: button.action) {
      actionLabel(button)
        .fontWeight(.semibold)
        .foregroundStyle(button.color)
        .background(button.color.opacity(0.15), in: .capsule)
        // A touch target as tall as the toast, without making it taller.
        .padding(.vertical, buttonInset)
        .contentShape(.rect)
        .padding(.vertical, -buttonInset)
    }
    .buttonStyle(.plain)
    // Centers the capsule on the message's first line, which the icon's frame matches.
    .alignmentGuide(.top) { $0[.top] + ($0.height - iconSize) / 2 }
    .padding(.leading, 2)
  }

  @ViewBuilder
  private func actionLabel(_ button: ToastButton) -> some View {
    if let systemImage = button.systemImage {
      Image(systemName: systemImage)
        .font(.footnote.weight(.semibold))
        .frame(width: buttonHeight, height: buttonHeight)
        .accessibilityLabel(Text(button.title))
    } else {
      Text(button.title)
        .fixedSize()
        .padding(.horizontal, 12)
        .frame(minHeight: buttonHeight)
    }
  }

  /// A close button in a small circle at the trailing end of the toast, filled like the action
  /// button's capsule but untinted. VoiceOver reaches it as the toast's Dismiss action instead.
  private var dismissButton: some View {
    Button(action: onDismiss) {
      Image(systemName: "xmark")
        .font(.footnote.weight(.semibold))
        .foregroundStyle(.secondary)
        .frame(width: buttonHeight, height: buttonHeight)
        .background(Color.primary.opacity(0.08), in: .circle)
        // A touch target as tall as the toast, without making it taller.
        .padding(.vertical, buttonInset)
        .contentShape(.rect)
        .padding(.vertical, -buttonInset)
    }
    .buttonStyle(.plain)
    // Centers the circle on the message's first line, like the action button.
    .alignmentGuide(.top) { $0[.top] + ($0.height - iconSize) / 2 }
    .accessibilityHidden(true)
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

private enum ToastGlassID: Hashable, Sendable {
  case message
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
    .init(icon: Image(systemName: "info.circle"), message: "Dismissible toast", showsDismissButton: true),
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
