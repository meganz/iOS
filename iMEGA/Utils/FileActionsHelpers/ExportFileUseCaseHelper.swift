import UIKit

extension UIViewController {
    @objc func exportFile(from node: MEGANode, sender: Any) {
        ExportFileRouter(presenter: UIApplication.mnz_presentingViewController(), sender: sender).export(node: NodeEntity(node: node))
    }
    
    @objc func exportMessageFile(from node: MEGANode, sender: Any) {
        ExportFileRouter(presenter: UIApplication.mnz_presentingViewController(), sender: sender).exportMessage(node: node)
    }
}

