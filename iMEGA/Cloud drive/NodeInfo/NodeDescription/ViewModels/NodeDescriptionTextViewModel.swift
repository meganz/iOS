import MEGASwift
import SwiftUI

final class NodeDescriptionTextViewModel: ObservableObject {
    @Published var isFocused: Bool
    @Published var descriptionString: String

    var placeholder: String {
        description.isPlaceholder ? description.text : ""
    }

    let editingDisabled: Bool
    private let description: NodeDescriptionViewModel.Description
    private let maxCharactersAllowed: Int
    private let descriptionUpdated: (String) -> Void
    private let saveDescription: (String) -> Void

    init(
        description: NodeDescriptionViewModel.Description,
        editingDisabled: Bool,
        maxCharactersAllowed: Int,
        descriptionUpdated: @escaping (String) -> Void,
        saveDescription: @escaping (String) -> Void
    ) {
        self.description = description
        self.descriptionString = description.isPlaceholder ? "" : description.text
        self.editingDisabled = editingDisabled
        self.maxCharactersAllowed = maxCharactersAllowed
        self.descriptionUpdated = descriptionUpdated
        self.saveDescription = saveDescription
        self.isFocused = false
    }

    func updatedDescriptionString(newValue: String) {
        if newValue.last?.isNewline == true {
            isFocused = false
            descriptionString.removeLast()
            saveDescription(descriptionString)
        } else {
            if newValue.unicodeScalars.count > maxCharactersAllowed {
                descriptionString = String(newValue.prefix(maxCharactersAllowed))
            }
            descriptionUpdated(descriptionString)
        }
    }
}
