import Foundation

/// A manager responsible for handling a collection of `BottomOverlayItem` objects.
/// It provides functionality to add, remove, show, and hide Tab Bar bottom overlay views.
@MainActor
final class BottomOverlayManager: NSObject {
    private var items: [BottomOverlayItem] = []
    
    func add(item: BottomOverlayItem) {
        items.append(item)
    }
    
    func remove(_ type: BottomSubViewType) {
        items.removeAll { $0.type == type }
    }

    func hideItem(_ type: BottomSubViewType) {
        setItemVisibility(for: type, hidden: true)
    }

    func showItem(_ type: BottomSubViewType) {
        setItemVisibility(for: type, hidden: false)
    }
    
    func contains(_ type: BottomSubViewType) -> Bool {
        items.first { $0.type == type } != nil
    }
    
    func view(for type: BottomSubViewType) -> UIView? {
        items.first { $0.type == type }?.view
    }
    
    func isItemHidden(_ type: BottomSubViewType) -> Bool {
        items.first { $0.type == type }?.view.isHidden ?? true
    }
    
    /// Returns the list of bottom overlay items sorted by their display priority and insertion order.
    ///
    /// The items are primarily sorted by their `priority.rawValue` in ascending order, meaning items with a lower priority value will
    /// appear first. When two items share the same priority, they are then sorted by their insertion order, with items added earlier appearing
    /// before items added later.
    /// - Returns: An array of `BottomOverlayItem` instances, sorted first by priority and then by insertion order.
    func sortedItems() -> [BottomOverlayItem] {
        items
            .enumerated()
            .sorted {
                ($0.element.priority.rawValue, $0.offset) < ($1.element.priority.rawValue, $1.offset)
            }
            .map { $0.element }
    }
    
    func setItemVisibility(
        for type: BottomSubViewType,
        hidden: Bool
    ) {
        for item in items where item.type == type {
            item.view.isHidden = hidden
        }
    }
    
    func allItemsHidden() -> Bool {
        items.allSatisfy { $0.view.isHidden }
    }
}

/// Used to define how a bottom overlay view is prioritized.
/// - Parameter rawValue: Numeric priority:
///    - 0 = normal
///    - 1 = high
///    - 2 = highest
/// - Returns: Determines the vertical position of the view within the bottom overlay.
///   Lower numeric values appear nearer the top, while higher numeric values appear at the bottom.
///
/// **Note**: Use `.highest` only in **exceptional** situations (e.g., progress bars) that must
/// appear at the very bottom of the overlay.
/// ```
/// ┌──────────────────┐
/// │┌────────────────┐│
/// │      normal      │
/// │└────────────────┘│
/// │┌────────────────┐│
/// │       high       │
/// │└────────────────┘│
/// │┌────────────────┐│
/// │      highest     │
/// │└────────────────┘│
/// │╔════════════════╗│
/// │║     Tab Bar    ║│
/// │╚════════════════╝│
/// └──────────────────┘
/// ```
enum BottomOverlayViewPriority: Int {
    /// Normal priority. Views appear toward the top of the overlay.
    case normal = 0
    
    /// High priority. Views appear near the bottom, but above `.highest`.
    case high
    
    /// The highest priority. Intended only for exceptional cases, like progress bars, that must appear at the very bottom of the overlay.
    case highest
}
 
/// A container that represents a single view within a bottom overlay.
/// Each `BottomOverlayItem` is identified by its unique `type` and includes:
/// - The UIView to display (`view`)
/// - A display `priority` for vertical ordering
/// - A fixed `height`
///
/// **Important**: Currently, the system is configured to handle only one `BottomOverlayItem` per `BottomSubViewType`.
/// If multiple items of the same type are added to a `BottomOverlayManager`, older items of that type will be removed or overshadowed in practice.
struct BottomOverlayItem {
    let type: BottomSubViewType
    let view: UIView
    let priority: BottomOverlayViewPriority
    let height: CGFloat?
}

/// Defines the various subview types managed by `BottomOverlayManager`.
/// - Note: Additional subview types should be added here.
enum BottomSubViewType: Equatable {
    /// A type representing the mini audio player.
    case audioPlayer
    /// A type representing the PSA banner
    case psa
}
