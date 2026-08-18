import SwiftUI

struct ChatRoomContextMenuOption: Identifiable, Hashable {
    let title: String
    let image: Image
    let action: () -> Void
    /// The option writes to the API, so it is greyed out while offline. The view decides that,
    /// from the connection state; the option only declares that it depends on one.
    var requiresConnection: Bool = false

    var id: String {
        title
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ChatRoomContextMenuOption, rhs: ChatRoomContextMenuOption) -> Bool {
        lhs.id == rhs.id
    }

    /// Most options are built with a trailing closure, which cannot be followed by another
    /// argument, so the flag is applied afterwards.
    func requiringConnection() -> Self {
        var option = self
        option.requiresConnection = true
        return option
    }
}

private struct ChatListActionsRequiringConnectionEnabledKey: EnvironmentKey {
    static let defaultValue = true
}

extension EnvironmentValues {
    /// Whether the chat list rows may offer the actions that write to the API. Set once on the
    /// list, so every row greys out its swipe actions, context menu and options sheet together
    /// while offline (IOS-12415), without each row having to watch the connection itself.
    var chatListActionsRequiringConnectionEnabled: Bool {
        get { self[ChatListActionsRequiringConnectionEnabledKey.self] }
        set { self[ChatListActionsRequiringConnectionEnabledKey.self] = newValue }
    }
}
