import SwiftUI

struct SwipeActionLabel: Identifiable, Hashable {
    let imageName: String
    let backgroundColor: Color
    let action: () -> Void
    /// The action writes to the API, so it is greyed out while offline.
    var requiresConnection: Bool = false

    var id: String {
        imageName
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(imageName)
    }
    
    static func == (lhs: SwipeActionLabel, rhs: SwipeActionLabel) -> Bool {
        lhs.id == rhs.id
    }
}
