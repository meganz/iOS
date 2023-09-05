import Foundation
import MEGAL10n
import VisionKit

extension ChatViewController: VNDocumentCameraViewControllerDelegate {
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        var docs = [UIImage]()
        for idx in 0 ..< scan.pageCount {
            let doc = scan.imageOfPage(at: idx)
            docs.append(doc)
        }
        
        controller.dismiss(animated: true) {
            let sb = UIStoryboard(name: "Cloud", bundle: nil)
            guard let vc = sb.instantiateViewController(withIdentifier: "DocScannerSaveSettingTableViewController") as? DocScannerSaveSettingTableViewController else {
                return
            }
            vc.docs = docs
            vc.chatRoom = self.chatRoom
            let nav = MEGANavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            nav.addLeftDismissButton(withText: Strings.localized("cancel", comment: ""))
            self.present(viewController: nav)
        }
    }
}
