import SwiftUI

struct ActionsView: View {
    var collisionType: NameCollisionType
    var duplicatedItem: DuplicatedItem
    var imageUrl: URL?
    var collisionImageUrl: URL?
    var actions: [NameCollisionAction]
    var action: (NameCollisionActionType) -> Void
    
    var body: some View {
        ForEach(actions) { actionItem in
            ActionView(viewModel: ActionViewModel(collisionType: collisionType, actionItem: actionItem))
                .gesture(
                    TapGesture()
                        .onEnded({ _ in
                            action(actionItem.actionType)
                        })
                )
        }
    }
}

struct ActionView: View {
    @Environment(\.colorScheme) private var colorScheme
    
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
            Divider()
            HStack(spacing: Constants.horizontalSpacing) {
                VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
                    VStack(alignment: .leading, spacing: Constants.textSpacing) {
                        Text(viewModel.actionTitle)
                            .font(.body.bold())
                            .foregroundColor(Color(Colors.General.Green._00C29A.name))
                        Text(viewModel.actionDescription)
                            .font(.footnote)
                            .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.8) : Color.black.opacity(0.8))
                    }
                    if viewModel.showItemView {
                        ItemView(name: viewModel.itemName, size: viewModel.actionItem.size, date: viewModel.actionItem.date, imageUrl: viewModel.actionItem.imageUrl, imagePlaceholder: viewModel.actionItem.itemPlaceholder)
                            .frame(maxWidth: .infinity)
                    }
                }
                Spacer()
                Image(Asset.Images.Generic.standardDisclosureIndicator.name)
                    .resizable()
                    .frame(width: Constants.disclosureSize.width, height: Constants.disclosureSize.height)
            }
            .padding()
            Divider()
        }
        .background(colorScheme == .dark ? Color(Colors.General.Black._2c2c2e.name) : Color.white)
        .frame(maxWidth: .infinity)
    }
}
