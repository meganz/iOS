import SwiftUI

@MainActor
final class NodeTagViewModel: ObservableObject {
    let tag: String
    let isSelectionEnabled: Bool
    @Published private(set) var isSelected: Bool

    var formattedTag: String {
        "#" + tag
    }

    init(tag: String, isSelectionEnabled: Bool, isSelected: Bool) {
        self.tag = tag
        self.isSelectionEnabled = isSelectionEnabled
        self.isSelected = isSelected
    }

    func toggle() {
        guard isSelectionEnabled else { return }
        isSelected.toggle()
    }
}
