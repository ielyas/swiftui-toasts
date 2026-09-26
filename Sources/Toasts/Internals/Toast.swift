import Foundation

@MainActor
@dynamicMemberLookup
internal final class ToastModel: ObservableObject, Identifiable {
  @Published internal var value: ToastValue
  /// A toast enters as a glass circle and expands into its full capsule; it collapses back before leaving.
  @Published internal var isExpanded = false
  internal var isDismissing = false
  /// A message too long for one line can be expanded to show in full; while expanded, the toast
  /// stays until the person collapses or dismisses it.
  @Published internal var isMessageExpanded = false
  internal init(value: ToastValue) {
    self.value = value
  }

  internal subscript<V>(dynamicMember keyPath: WritableKeyPath<ToastValue, V>) -> V {
    get { value[keyPath: keyPath] }
    set { value[keyPath: keyPath] = newValue }
  }
}
