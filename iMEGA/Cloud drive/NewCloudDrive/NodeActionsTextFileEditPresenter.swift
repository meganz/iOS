import MEGADomain
import MEGATextEditor
import UIKit

/// Opens a text file in edit mode from a Cloud Drive list action.
@objc @MainActor
final class NodeActionsTextFileEditPresenter: NSObject {
    /// A Markdown file opens in the editor only from a screen that allows text editing.
    /// Other files keep the navigation controller, so their flow does not change.
    static func presenter(
        for node: NodeEntity,
        in navigationController: UINavigationController,
        isMarkdownEditorEnabled: Bool
    ) -> UIViewController {
        let route = MarkdownTextEditorRoute(fileName: node.name, sizeInBytes: node.size, isEnabled: isMarkdownEditorEnabled)
        guard route != .otherFile else { return navigationController }
        return navigationController.viewControllers.last ?? navigationController
    }

    /// Starts the edit mode on the screen that the navigation controller shows.
    @objc static func editAfterOpen(in navigationController: UINavigationController) {
        switch navigationController.viewControllers.last {
        case let screen as TextEditorViewController:
            screen.editAfterOpen()
        case let screen as MarkdownTextEditorViewController:
            screen.editAfterOpen()
        case let screen as PreviewDocumentViewController:
            screen.showUnknownEncodeHud = true
        default:
            break
        }
    }
}
