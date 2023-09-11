import MEGASwiftUI
import SwiftUI

struct ChipViewModel: Identifiable {
    
    var id: String {
        chipId.description
    }
    
    let chipId: ChipId
    let pill: PillViewModel
    let select: () async -> Void
}
