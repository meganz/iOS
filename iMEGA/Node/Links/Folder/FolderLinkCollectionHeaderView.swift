import MEGAUIKit
import UIKit

final class FolderLinkCollectionHeaderView: UICollectionReusableView {
    static var reusableIdentifier: String { "FolderLinkCollectionHeaderView" }

    func addContentView(_ contentView: UIView) {
        wrap(contentView)
    }
}
