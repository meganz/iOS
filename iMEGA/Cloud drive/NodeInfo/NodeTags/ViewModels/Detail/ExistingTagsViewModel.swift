import MEGASwift
import SwiftUI

@MainActor
final class ExistingTagsViewModel: ObservableObject {
    @Published var tags: [String]
    @Published var selectedTags: Set<String>

    init(tags: [String] = [], selectedTags: Set<String> = []) {
        self.tags = tags
        self.selectedTags = selectedTags
    }

    var formattedTags: [String] {
        tags.elementsPrepended(with: "#")
    }

    func toggle(tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }

    func addAndSelectNewTag(_ tag: String) {
        tags.append(tag)
        selectedTags.insert(tag)
    }

    func isSelected(_ tag: String) -> Bool {
       selectedTags.contains(tag.hasPrefix("#") ? String(tag.dropFirst()) : tag)
    }
}
