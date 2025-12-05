import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import SwiftUI

struct NavigationBarItemViewBuilder {

    @MainActor @ViewBuilder
    static func makeView(for viewModel: NavigationBarItemViewModel) -> some View {
        switch viewModel.viewType {
        case .cameraUploadStatus(let statusViewModel, let action):
            CameraUploadStatusButtonView(viewModel: statusViewModel)
                .onTapGesture(perform: action)

        case .imageButton(let image, let action):
            Button(action: action) {
                Image(uiImage: image)
                    .foregroundStyle(TokenColors.Icon.primary.swiftUI)
            }

        case .textButton(let text, let action):
            Button(action: action) {
                Text(text)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
            }

        case .contextMenu(let config, let manager):
            makeContextMenuView(config: config, manager: manager)
        }
    }

    // MARK: - Private Helpers

    @MainActor @ViewBuilder
    private static func makeContextMenuView(
        config: CMConfigEntity,
        manager: ContextMenuManager
    ) -> some View {
        manager.menu(with: config) {
            Image(uiImage: MEGAAssets.UIImage.moreNavigationBar)
        }
    }
}
