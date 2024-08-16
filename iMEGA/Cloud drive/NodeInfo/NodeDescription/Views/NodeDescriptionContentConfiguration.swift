import UIKit

struct NodeDescriptionContentConfiguration: UIContentConfiguration {
    let description: NodeDescriptionViewModel.Description
    let editingDisabled: Bool
    let maxCharactersAllowed: Int
    let descriptionUpdated: (String) -> Void
    let saveDescription: (String) -> Void

    init(
        description: NodeDescriptionViewModel.Description,
        editingDisabled: Bool,
        maxCharactersAllowed: Int,
        descriptionUpdated: @escaping (String) -> Void,
        saveDescription: @escaping (String) -> Void
    ) {
        self.description = description
        self.editingDisabled = editingDisabled
        self.maxCharactersAllowed = maxCharactersAllowed
        self.descriptionUpdated = descriptionUpdated
        self.saveDescription = saveDescription
    }

    func makeContentView() -> any UIView & UIContentView {
        NodeDescriptionTextContentView(
            configuration: self,
            viewModel: NodeDescriptionTextContentViewModel(
                maxCharactersAllowed: maxCharactersAllowed,
                editingDisabled: editingDisabled,
                textViewEdgeInsets: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16),
                descriptionUpdated: descriptionUpdated,
                saveDescription: saveDescription
            )
        )
    }

    func updated(for state: any UIConfigurationState) -> NodeDescriptionContentConfiguration {
        self
    }
}
