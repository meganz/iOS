import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGASwiftUI
import SwiftUI

struct ActionsView: View {
    var duplicatedItem: DuplicatedItem
    var imageUrl: URL?
    var collisionImageUrl: URL?
    var actions: [NameCollisionAction]
    var action: (NameCollisionActionType) -> Void
    
    var body: some View {
        ForEach(actions) { actionItem in
            Button {
                action(actionItem.actionType)
            } label: {
                ActionView(viewModel: ActionViewModel(actionItem: actionItem))
            }
        }
    }
}

struct ActionView: View {
    @ObservedObject var viewModel: ActionViewModel

    private enum Constants {
        static let horizontalSpacing: CGFloat = 6
        static let verticalSpacing: CGFloat = 12
        static let textSpacing: CGFloat = 4
        
        enum disclosureSize {
            static let width: CGFloat = 8
            static let height: CGFloat = 16
        }
    }
    
    var body: some View {
        VStack {
            MEGADivider()
            HStack(spacing: Constants.horizontalSpacing) {
                VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
                    VStack(alignment: .leading, spacing: Constants.textSpacing) {
                        Text(viewModel.actionTitle)
                            .font(.body.bold())
                            .foregroundColor(TokenColors.Text.primary.swiftUI)
                        if let description = viewModel.actionDescription {
                            Text(description)
                                .multilineTextAlignment(.leading)
                                .font(.footnote)
                                .foregroundColor(TokenColors.Text.primary.swiftUI)
                        }
                    }
                    if viewModel.showItemView {
                        ItemView(name: viewModel.itemName, size: viewModel.actionItem.size, date: viewModel.actionItem.date, imageUrl: viewModel.actionItem.imageUrl, imagePlaceholder: viewModel.actionItem.imagePlaceholder)
                            .frame(maxWidth: .infinity)
                    }
                }
                Spacer()
                MEGAAssets.Image.standardDisclosureIndicatorDesignToken
                    .resizable()
                    .frame(width: Constants.disclosureSize.width, height: Constants.disclosureSize.height)
            }
            .padding()
            MEGADivider()
        }
        .background()
        .frame(maxWidth: .infinity)
    }
}
