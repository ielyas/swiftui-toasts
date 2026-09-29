#if canImport(UIKit)
  import UIKit

  @MainActor
  func announceToAccessibility(_ message: String) {
    guard !message.isEmpty, UIAccessibility.isVoiceOverRunning else { return }

    let attributedMessage = createAttributedAccessibilityMessage(message)
    UIAccessibility.post(notification: .announcement, argument: attributedMessage)
  }

  private func createAttributedAccessibilityMessage(_ message: String) -> NSAttributedString {
    let attributes: [NSAttributedString.Key: Any] = [
      .accessibilitySpeechQueueAnnouncement: false,
      .accessibilitySpeechAnnouncementPriority: UIAccessibilityPriority.high.rawValue,
    ]
    return NSAttributedString(string: message, attributes: attributes)
  }
#elseif os(macOS)
  import AppKit

  @MainActor
  func announceToAccessibility(_ message: String) {
    guard !message.isEmpty, NSWorkspace.shared.isVoiceOverEnabled else { return }

    NSAccessibility.post(
      element: NSApp.mainWindow as Any,
      notification: .announcementRequested,
      userInfo: [
        .announcement: message,
        .priority: NSAccessibilityPriorityLevel.high.rawValue,
      ]
    )
  }
#endif
