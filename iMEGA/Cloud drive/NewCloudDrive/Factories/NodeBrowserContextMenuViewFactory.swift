import MEGAAssets
import SwiftUI

struct NodeBrowserContextMenuViewFactory {
    typealias MakeNavItemsFactory = () -> CloudDriveViewControllerNavItemsFactory
    let makeNavItemsFactory: MakeNavItemsFactory

    func makeContextMenuWithButtonView() -> ContextMenuWithButtonView<Image>? {
        makeNavItemsFactory().contextMenu {
            Image(uiImage: MEGAAssets.UIImage.moreNavigationBar)
        }
    }

    func makeAddMenuWithButtonView() -> ContextMenuWithButtonView<Image>? {
        makeNavItemsFactory().addMenu {
            Image(uiImage: MEGAAssets.UIImage.navigationbarAdd)
        }
    }
}
