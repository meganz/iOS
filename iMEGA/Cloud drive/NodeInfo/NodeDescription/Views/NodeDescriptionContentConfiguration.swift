import UIKit

struct NodeDescriptionContentConfiguration: UIContentConfiguration {
    let description: NodeDescriptionViewModel.Description
    private let editingDisabled: Bool
    private let maxCharactersAllowed: Int
    private let placeholderText: String
    private let descriptionUpdated: (String) -> Void
    private let saveDescription: (String) -> Void
    private let updatedLayout: (() -> Void) -> Void

    init(
        description: NodeDescriptionViewModel.Description,
        editingDisabled: Bool,
        maxCharactersAllowed: Int,
        placeholderText: String,
        descriptionUpdated: @escaping (String) -> Void,
        saveDescription: @escaping (String) -> Void,
        updatedLayout: @escaping (() -> Void) -> Void
    ) {
        self.description = description
        self.editingDisabled = editingDisabled
        self.maxCharactersAllowed = maxCharactersAllowed
        self.placeholderText = placeholderText
        self.descriptionUpdated = descriptionUpdated
        self.saveDescription = saveDescription
        self.updatedLayout = updatedLayout
    }

    func makeContentView() -> any UIView & UIContentView {
        NodeDescriptionTextContentView(
            configuration: self,
            viewModel: NodeDescriptionTextContentViewModel(
                maxCharactersAllowed: maxCharactersAllowed,
                editingDisabled: editingDisabled, 
                placeholderText: placeholderText,
                textViewEdgeInsets: UIEdgeInsets(top: 11, left: 16, bottom: 11, right: 16),
                descriptionUpdated: descriptionUpdated,
                saveDescription: saveDescription,
                updatedLayout: updatedLayout
            )
        )
    }

    func updated(for state: any UIConfigurationState) -> NodeDescriptionContentConfiguration {
        self
    }
}
