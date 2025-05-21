import SwiftUI

struct OccurrenceContextMenuOption: Identifiable, Hashable {
    let title: String
    let image: Image
    let action: (ScheduleMeetingOccurrence) -> Void
    
    var id: String {
        title
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: OccurrenceContextMenuOption, rhs: OccurrenceContextMenuOption) -> Bool {
        lhs.id == rhs.id
    }
}
