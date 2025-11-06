import MEGAUIKit
import UIKit

final class FilesExplorerGridHeaderView: UICollectionReusableView {
    static var reusableIdentifier: String { "FilesExplorerGridHeaderView" }

    func addContentView(_ contentView: UIView) {
        wrap(contentView)
    }
}
