import SwiftUI

struct GetLinkView: UIViewControllerRepresentable {
    private let nodes: [MEGANode]
    
    init(nodes: [MEGANode]) {
        self.nodes = nodes
    }
    
    func makeUIViewController(context: Context) -> UINavigationController {
        return GetLinkViewController.instantiate(withNodes: nodes)
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}
