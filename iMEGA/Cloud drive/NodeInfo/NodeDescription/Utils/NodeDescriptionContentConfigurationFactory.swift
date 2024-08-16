import SwiftUI
import UIKit

struct NodeDescriptionContentConfigurationFactory {
    private init() {}

    static func makeContentConfiguration(
        viewModel: NodeDescriptionViewModel,
        maxCharactersAllowed: Int,
        descriptionUpdated: @escaping (String) -> Void,
        saveDescription: @escaping (String) -> Void
    ) -> some UIContentConfiguration {
        if #available(iOS 16.0, *) {
            return makeHostingConfiguration(
                viewModel: viewModel,
                maxCharactersAllowed: maxCharactersAllowed,
                descriptionUpdated: descriptionUpdated,
                saveDescription: saveDescription
            )
        } else {
            return makeCustomContentConfiguration(
                viewModel: viewModel,
                maxCharactersAllowed: maxCharactersAllowed,
                descriptionUpdated: descriptionUpdated,
                saveDescription: saveDescription
            )
        }
    }

    @available(iOS 16.0, *)
    private static func makeHostingConfiguration(
        viewModel: NodeDescriptionViewModel,
        maxCharactersAllowed: Int,
        descriptionUpdated: @escaping (String) -> Void,
        saveDescription: @escaping (String) -> Void
    ) -> UIHostingConfiguration<NodeDescriptionTextView, EmptyView> {
        UIHostingConfiguration {
            NodeDescriptionTextView(
                viewModel: NodeDescriptionTextViewModel(
                    description: viewModel.description,
                    editingDisabled: viewModel.hasReadOnlyAccess,
                    maxCharactersAllowed: maxCharactersAllowed,
                    descriptionUpdated: descriptionUpdated,
                    saveDescription: saveDescription
                )
            )
        }
        .margins(.all, 0)
    }

    private static func makeCustomContentConfiguration(
        viewModel: NodeDescriptionViewModel,
        maxCharactersAllowed: Int,
        descriptionUpdated: @escaping (String) -> Void,
        saveDescription: @escaping (String) -> Void
    ) -> some UIContentConfiguration {
        NodeDescriptionContentConfiguration(
            description: viewModel.description,
            editingDisabled: viewModel.hasReadOnlyAccess, 
            maxCharactersAllowed: maxCharactersAllowed,
            descriptionUpdated: descriptionUpdated,
            saveDescription: saveDescription
        )
    }
}
