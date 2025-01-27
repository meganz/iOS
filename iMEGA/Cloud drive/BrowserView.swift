import MEGADomain
import SwiftUI

struct BrowserView: UIViewControllerRepresentable {
    private let browserAction: BrowserAction
    private let isChildBrowser: Bool
    private let parentNode: MEGANode?
    @Binding private var selectedNode: NodeEntity?

    init(browserAction: BrowserAction,
         isChildBrowser: Bool,
         parentNode: MEGANode? = nil,
         selectedNode: Binding<NodeEntity?>) {
        self.browserAction = browserAction
        self.isChildBrowser = isChildBrowser
        self.parentNode = parentNode
        _selectedNode = selectedNode
    }
    
    func makeUIViewController(context: Context) -> MEGANavigationController {
        guard let navigationController = UIStoryboard(name: "Cloud", bundle: nil)
            .instantiateViewController(withIdentifier: "BrowserNavigationControllerID") as? MEGANavigationController,
              let browserVC = navigationController.viewControllers.first as? BrowserViewController else {
            fatalError("Could not instantiate BrowserViewController")
        }
        browserVC.browserAction = browserAction
        browserVC.isChildBrowser = isChildBrowser
        browserVC.parentNode = parentNode
        browserVC.browserViewControllerDelegate = context.coordinator
        return navigationController
    }

    func updateUIViewController(_ uiViewController: MEGANavigationController, context: Context) {}
    
    final class Coordinator: NSObject, BrowserViewControllerDelegate {
        @Binding var selectedNode: NodeEntity?
        
        init(selectedNode: Binding<NodeEntity?>) {
            _selectedNode = selectedNode
        }
        
        func didSelect(_ node: MEGANode) {
            selectedNode = node.toNodeEntity()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(selectedNode: $selectedNode)
    }
}
