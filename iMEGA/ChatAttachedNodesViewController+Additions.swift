import Foundation
import MEGAL10n

extension ChatAttachedNodesViewController {
    @objc func nodeCountTitle(_ count: Int) -> String {
        guard count > 0 else {
            return Strings.Localizable.selectTitle
        }
        return Strings.Localizable.General.Format.itemsSelected(count)
    }
}
