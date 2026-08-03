import MEGADomain
import UIKit

extension UIViewController {
    @objc func exportFile(from node: MEGANode, sender: Any) {
        exportFile(from: node, sender: sender, isFolderLink: false)
    }

    /// A folder link node lives in its own SDK instance, so the download backing the export has to be
    /// told where to look it up — otherwise it fails to find the node and the export silently stops.
    func exportFile(from node: MEGANode, sender: Any, isFolderLink: Bool) {
        ExportFileRouter(
            presenter: UIApplication.mnz_presentingViewController(),
            sender: sender,
            isFolderLink: isFolderLink
        ).export(node: node.toNodeEntity())
    }
    
    @objc func exportMessageFile(from node: MEGANode, messageId: HandleEntity, chatId: HandleEntity, sender: Any) {
        ExportFileRouter(presenter: UIApplication.mnz_presentingViewController(), sender: sender).exportMessage(node: node, messageId: messageId, chatId: chatId)
    }
}
