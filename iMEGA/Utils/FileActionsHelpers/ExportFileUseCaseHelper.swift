import MEGADomain
import UIKit

extension UIViewController {
    @objc func exportFile(from node: MEGANode, sender: Any) {
        ExportFileRouter(presenter: UIApplication.mnz_presentingViewController(), sender: sender).export(node: node.toNodeEntity())
    }
    
    @objc func exportMessageFile(from node: MEGANode, messageId: HandleEntity, chatId: HandleEntity, sender: Any) {
        ExportFileRouter(presenter: UIApplication.mnz_presentingViewController(), sender: sender).exportMessage(node: node, messageId: messageId, chatId: chatId)
    }
}
