import XCTest
import SwiftUI
@testable import Toasts

@MainActor
final class ToastManagerTests: XCTestCase {
  func testAppendToast() {
    let manager = ToastManager()
    let toast = ToastValue(message: "Test Message")
    
    let model = manager.append(toast)
    
    XCTAssertEqual(manager.models.count, 1)
    XCTAssertTrue(manager.models.contains(where: { $0 === model }))
    XCTAssertEqual(model.message, "Test Message")
  }
  
  func testRemoveToast() {
    let manager = ToastManager()
    let toast = ToastValue(message: "Test Message")
    let model = manager.append(toast)
    
    manager.remove(model)
    
    XCTAssertTrue(manager.models.isEmpty)
  }
  
  func testIsPresented() {
    let manager = ToastManager()
    
    XCTAssertFalse(manager.isPresented)
    
    let toast = ToastValue(message: "Test Message")
    manager.append(toast)
    
    XCTAssertTrue(manager.isPresented)
  }
  
  func testOnAppear() {
    let manager = ToastManager()
    
    XCTAssertFalse(manager.isAppeared)
    
    manager.onAppear()
    
    XCTAssertTrue(manager.isAppeared)
  }
  
  func testStartRemovalTask() async {
    let manager = ToastManager()
    let toast = ToastValue(message: "Test Message", duration: 0.1)
    let model = manager.append(toast)
    
    await manager.startRemovalTask(for: model)
    
    XCTAssertTrue(manager.models.isEmpty)
  }
  
  func testDismissCollapsesThenRemoves() async {
    let manager = ToastManager()
    let model = manager.append(ToastValue(message: "Test Message"))
    model.isExpanded = true

    await manager.dismiss(model)

    XCTAssertFalse(model.isExpanded)
    XCTAssertTrue(manager.models.isEmpty)
  }


  func testDismissIsIdempotent() async {
    let manager = ToastManager()
    let model = manager.append(ToastValue(message: "Test Message"))
    let other = manager.append(ToastValue(message: "Other"))

    async let first: Void = manager.dismiss(model)
    async let second: Void = manager.dismiss(model)
    _ = await (first, second)

    XCTAssertEqual(manager.models.count, 1)
    XCTAssertTrue(manager.models.first === other)
  }

  func testExpandedMessageIsNotDismissedByTimer() async {
    let manager = ToastManager()
    let model = manager.append(ToastValue(message: "A long message", duration: 0.1))
    model.isExpanded = true
    model.isMessageExpanded = true

    await manager.startRemovalTask(for: model)

    XCTAssertEqual(manager.models.count, 1)
  }

  func testCollapsedMessageDismissesSooner() {
    let manager = ToastManager()
    let model = manager.append(ToastValue(message: "A long message", duration: 8))
    XCTAssertEqual(manager.dismissDelay(for: model), 8)

    model.hasCollapsedMessage = true
    XCTAssertEqual(manager.dismissDelay(for: model), 2)

    let loading = manager.append(ToastValue(message: "Loading", duration: nil))
    loading.hasCollapsedMessage = true
    XCTAssertNil(manager.dismissDelay(for: loading))
  }

  func testDismissCollapsesExpandedMessage() async {
    let manager = ToastManager()
    let model = manager.append(ToastValue(message: "A long message"))
    model.isExpanded = true
    model.isMessageExpanded = true

    await manager.dismiss(model)

    XCTAssertFalse(model.isMessageExpanded)
    XCTAssertTrue(manager.models.isEmpty)
  }

  func testHitTestingFollowsToastFrames() {
    let manager = ToastManager()
    let model = manager.append(ToastValue(message: "Test Message"))
    manager.setFrame(CGRect(x: 20, y: 700, width: 300, height: 48), for: model)

    XCTAssertTrue(manager.containsToast(at: CGPoint(x: 100, y: 720)))
    XCTAssertFalse(manager.containsToast(at: CGPoint(x: 100, y: 400)))

    manager.remove(model)
    XCTAssertFalse(manager.containsToast(at: CGPoint(x: 100, y: 720)))
  }

  func testAppendWithTask() async throws {
    let manager = ToastManager()
    
    let result = try await manager.append(
      message: "Loading...",
      task: {
        try await Task.sleep(for: .seconds(0.1))
        return "Success"
      },
      onSuccess: { result in
        ToastValue(icon: Image(systemName: "checkmark.circle"), message: result)
      },
      onFailure: { error in
        ToastValue(icon: Image(systemName: "xmark.circle"), message: error.localizedDescription)
      }
    )
    
    XCTAssertEqual(result, "Success")
    XCTAssertEqual(manager.models.count, 1)
    XCTAssertEqual(manager.models.first?.message, "Success")
  }

  func testAppendWithErrorTask() async throws {
    let manager = ToastManager()

    do {
      try await manager.append(
        message: "Loading...",
        task: {
          try await Task.sleep(for: .seconds(0.1))
          throw NSError(domain: "", code: 0)
        },
        onSuccess: { result in
          ToastValue(icon: Image(systemName: "checkmark.circle"), message: result)
        },
        onFailure: { error in
          ToastValue(icon: Image(systemName: "xmark.circle"), message: "Error")
        }
      )
    } catch {}
    XCTAssertEqual(manager.models.count, 1)
    XCTAssertEqual(manager.models.first?.message, "Error")
  }

  func testToastKindDefaultsToInfo() {
    XCTAssertEqual(ToastValue(message: "Test Message").kind, .info)
    XCTAssertEqual(ToastValue(message: "Test Message", kind: .error).kind, .error)
  }

  func testLoadingToastPlaysItsResultsHaptic() async throws {
    let manager = ToastManager()

    let loading = Task {
      try await manager.append(
        message: "Loading...",
        task: { try await Task.sleep(for: .seconds(0.1)) },
        onSuccess: { ToastValue(message: "Done", kind: .success) },
        onFailure: { _ in ToastValue(message: "Error", kind: .error) }
      )
    }
    await Task.yield()
    XCTAssertNil(manager.models.first?.kind)

    try await loading.value
    XCTAssertEqual(manager.models.first?.kind, .success)
  }
}
