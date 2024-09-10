import MEGADesignToken
import MEGAL10n
import SwiftUI

struct NameCollisionView: View {
    @ObservedObject var viewModel: NameCollisionViewModel
    
    private enum Constants {
        static let verticalSpacing: CGFloat = 12
    }
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text(viewModel.duplicatedItem.isFile ? Strings.Localizable.NameCollision.Title.file : Strings.Localizable.NameCollision.Title.folder)
                    .font(.headline)
                Spacer()
                Button(Strings.Localizable.cancel) {
                    viewModel.cancelResolveNameCollisions()
                }
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                .accentColor(Color.primary)
            }
            .padding()
            
            ScrollView(.vertical) {
                VStack(spacing: Constants.verticalSpacing) {
                    HeaderView(viewModel: HeaderViewModel(isFile: viewModel.duplicatedItem.isFile, name: viewModel.duplicatedItem.name))
                    
                    if !viewModel.duplicatedItem.isFile {
                        ItemView(name: viewModel.duplicatedItem.name, size: viewModel.duplicatedItem.collisionFileSize, date: viewModel.duplicatedItem.collisionFileDate, imageUrl: viewModel.thumbnailCollisionUrl, imagePlaceholder: viewModel.duplicatedItem.imagePlaceholder)
                            .padding()
                    }
                    ActionsView(duplicatedItem: viewModel.duplicatedItem, imageUrl: viewModel.thumbnailUrl, collisionImageUrl: viewModel.thumbnailCollisionUrl, actions: viewModel.actionsForCurrentDuplicatedItem()) { action in
                        viewModel.selectedAction(action)
                    }
                    
                    if viewModel.remainingCollisionsCount > 1 {
                        ApplyToAllView(
                            text: Strings.Localizable.NameCollision.applyToAll(viewModel.remainingCollisionsCount),
                            applyToAllSelected: $viewModel.applyToAllEnabled)
                    }
                }
            }
        }
        .background()
        .onAppear {
            viewModel.onViewAppeared()
        }
    }
}
