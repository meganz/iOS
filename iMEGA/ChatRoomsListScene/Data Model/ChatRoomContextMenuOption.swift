import SwiftUI

struct ChatRoomContextMenuOption: Identifiable, Hashable {
    let title: String
    let image: Image
    let action: () -> Void
    
    var id: String {
        title
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ChatRoomContextMenuOption, rhs: ChatRoomContextMenuOption) -> Bool {
        lhs.id == rhs.id
    }
}
