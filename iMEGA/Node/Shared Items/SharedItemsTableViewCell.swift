import UIKit

@objc protocol SharedItemsTableViewCellDelegate {
    func didTapInfoButton(sender: UIButton)
}

final class SharedItemsTableViewCell: UITableViewCell {

    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var nameLabel: MEGALabel!
    @IBOutlet weak var labelView: UIView!
    @IBOutlet weak var labelImageView: UIImageView!
    @IBOutlet weak var favouriteView: UIView!
    @IBOutlet weak var favouriteImageView: UIImageView!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var permissionsButton: UIButton!
    @IBOutlet weak var infoButton: UIButton!
    
    @objc var delegate: SharedItemsTableViewCellDelegate?
    
    @objc var nodeHandle: UInt64 = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        updateAppearance()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
    }
    
    @IBAction func infoButtonTouchUpInside(_ sender: UIButton) {
        delegate?.didTapInfoButton(sender: sender)
    }
    
    // Pragma mark: - Private
    
    func updateAppearance() {
        infoLabel.textColor = UIColor.mnz_subtitles(for: traitCollection)
        backgroundColor = UIColor.mnz_tertiaryBackground(traitCollection)
    }

}
