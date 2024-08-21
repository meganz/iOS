import UIKit

struct NodeDescriptionContentConfiguration: UIContentConfiguration {
    let description: NodeDescriptionViewModel.Description
    private let editingDisabled: Bool
    private let maxCharactersAllowed: Int
    private let descriptionUpdated: (String) -> Void
    private let saveDescription: (String) -> Void
    private let updatedLayout: (() -> Void) -> Void

    init(
        description: NodeDescriptionViewModel.Description,
        editingDisabled: Bool,
        maxCharactersAllowed: Int,
        descriptionUpdated: @escaping (String) -> Void,
        saveDescription: @escaping (String) -> Void,
        updatedLayout: @escaping (() -> Void) -> Void
    ) {
        self.description = description
        self.editingDisabled = editingDisabled
        self.maxCharactersAllowed = maxCharactersAllowed
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
