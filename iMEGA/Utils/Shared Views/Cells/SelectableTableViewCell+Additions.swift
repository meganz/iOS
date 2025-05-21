import MEGAAssets
import MEGADesignToken

extension SelectableTableViewCell {
    @objc func imageViewDesignToken() {
        redCheckmarkImageView?.image = MEGAAssets.UIImage.turquoiseCheckmark
        redCheckmarkImageView?.tintColor = TokenColors.Support.success
    }
}
