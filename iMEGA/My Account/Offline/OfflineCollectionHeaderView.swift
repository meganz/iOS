import MEGAUIKit
import UIKit

final class OfflineCollectionHeaderView: UICollectionReusableView {
    static var reusableIdentifier: String { "OfflineCollectionHeaderView" }

    func addContentView(_ contentView: UIView) {
        wrap(contentView)
    }
}
