import SwiftUI

struct NodeBrowserContextMenuViewFactory {
    let makeNavItemsFactory: () -> CloudDriveViewControllerNavItemsFactory

    func makeContextMenuWithButtonView() -> ContextMenuWithButtonView<Image>? {
        makeNavItemsFactory().contextMenu {
            Image(uiImage: UIImage.moreNavigationBar)
        }
    }

    func makeAddMenuWithButtonView() -> ContextMenuWithButtonView<Image>? {
        makeNavItemsFactory().addMenu {
            Image(uiImage: UIImage.navigationbarAdd)
        }
    }
}
