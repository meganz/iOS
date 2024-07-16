import SwiftUI

struct NodeBrowserContextMenuViewFactory {
    let nodeSource: NodeSource
    let isHidden: Bool?
    let makeNavItemsFactory: (_ nodeSource: NodeSource, _ isHidden: Bool?) -> CloudDriveViewControllerNavItemsFactory

    func makeContextMenuWithButtonView() -> ContextMenuWithButtonView<Image>? {
        makeNavItemsFactory(nodeSource, isHidden).contextMenu {
            Image(uiImage: UIImage.moreNavigationBar)
        }
    }

    func makeAddMenuWithButtonView() -> ContextMenuWithButtonView<Image>? {
        makeNavItemsFactory(nodeSource, isHidden).addMenu {
            Image(uiImage: UIImage.navigationbarAdd)
        }
    }
}
