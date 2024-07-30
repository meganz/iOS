import SwiftUI

struct ContactsView: UIViewControllerRepresentable {
    private let nodes: [MEGANode]
    private let mode: ContactsMode
    
    init(nodes: [MEGANode], mode: ContactsMode) {
        self.nodes = nodes
        self.mode = mode
    }
    
    func makeUIViewController(context: Context) -> MEGANavigationController {
        let contactsStoryboard = UIStoryboard(name: "Contacts", bundle: nil)
        guard let navigationController = contactsStoryboard.instantiateViewController(withIdentifier: "ContactsNavigationControllerID") as? MEGANavigationController else {
            return MEGANavigationController()
        }
        let contactsViewController = navigationController.viewControllers.first as! ContactsViewController
        contactsViewController.nodesArray = nodes
        contactsViewController.contactsMode = mode
        
        return navigationController
    }
    
    func updateUIViewController(_ uiViewController: MEGANavigationController, context: Context) {}
}
