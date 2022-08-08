import Foundation
import MEGADomain

final class NodeManagementRouter: NSObject {

    private weak var navigationController: UINavigationController?

    init(navigationController: UINavigationController? = nil) {
        self.navigationController = navigationController
    }

    // MARK: - Public

    func showMoveToRubbishBin(for node: MEGANode) {
        node.mnz_moveToTheRubbishBin(completion: {})
    }

    func showCopyDestination(for node: MEGANode) {
        let navigation = UIStoryboard(name: "Cloud", bundle: nil)
            .instantiateViewController(withIdentifier: "BrowserNavigationControllerID") as! UINavigationController
        let browserViewController = navigation.viewControllers.first as! BrowserViewController
        browserViewController.browserAction = .copy
        browserViewController.selectedNodesArray = [node]

        navigationController?.present(navigation, animated: true, completion: nil)
    }

    func showMoveDestination(for node: MEGANode) {
        let navigation = UIStoryboard(name: "Cloud", bundle: nil)
            .instantiateViewController(withIdentifier: "BrowserNavigationControllerID") as! UINavigationController
        let browserViewController = navigation.viewControllers.first as! BrowserViewController
        browserViewController.browserAction = .move
        browserViewController.selectedNodesArray = [node]

        navigationController?.present(navigation, animated: true, completion: nil)
    }

    func showLabelColorAction(for node: MEGANode) {
        ActionSheetFactory().nodeLabelColorView(forNode: node.handle) {
            [navigationController] (actionViewControllerResult) in
            switch actionViewControllerResult {
            case .failure:
                break // not implemented, save for later to define.
            case .success(let actionSheetViewController):
                navigationController?.present(actionSheetViewController, animated: true, completion: nil)
            }
        }
    }
    
    func showEditTextFile(for node: MEGANode) {
        if let vc = navigationController?.viewControllers.last {
            node.mnz_editTextFile(in: vc)
        }
    }
}
