import MEGADesignToken
import MEGAUIKit
import UIKit

class VideoExplorerTableViewCell: UITableViewCell {
    @IBOutlet private weak var videoThumbnailImageView: UIImageView!
    @IBOutlet private weak var placeholderImageView: UIImageView!
    @IBOutlet private weak var videoTitleLabel: UILabel!
    @IBOutlet private weak var parentFolderNameLabel: UILabel!
    @IBOutlet private weak var durationLabel: UILabel!
    @IBOutlet private weak var playIconView: PhotoCarouselVideoIcon!
    @IBOutlet private weak var moreButton: UIButton!
    @IBOutlet private weak var moreButtonWidthConstraint: NSLayoutConstraint!
    
    private var moreButtonDefaultWidth: CGFloat = 0.0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        moreButtonDefaultWidth = moreButtonWidthConstraint.constant
        videoTitleLabel.lineBreakMode = .byTruncatingMiddle
        contentView.backgroundColor = TokenColors.Background.page
        videoTitleLabel.textColor = TokenColors.Text.primary
        parentFolderNameLabel.textColor = TokenColors.Text.secondary
        durationLabel.textColor = TokenColors.Text.secondary
        moreButton.tintColor = TokenColors.Icon.secondary
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        moreButton.isHidden = editing
        moreButtonWidthConstraint.constant = editing ? 0.0 : moreButtonDefaultWidth
    }

    var viewModel: VideoExplorerTableCellViewModel? {
        didSet {
            guard let viewModel = viewModel else {
                placeholderImageView.isHidden = false
                videoThumbnailImageView.image = nil
                videoTitleLabel.text = nil
                durationLabel.text = nil
                parentFolderNameLabel.text = nil
                return
            }
            
            if viewModel.hasThumbnail {
                viewModel.loadThumbnail { [weak self] image, nodeHandle in
                    guard let self = self, nodeHandle == self.viewModel?.nodeHandle else { return }
                    self.placeholderImageView.isHidden = true
                    self.videoThumbnailImageView.image = image
                }
            }
            
            videoTitleLabel.attributedText = viewModel.createAttributedTitle()
            durationLabel.text = viewModel.duration
            parentFolderNameLabel.text = viewModel.parentFolderName
        }
    }
    
    @IBAction func moreButtonTapped(_ sender: UIButton) {
        viewModel?.moreButtonTapped(cell: sender)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        viewModel = nil
    }
    
    // MARK: - Private
    
    private func updateAppearance(with trait: UITraitCollection) {
        guard let viewModel = viewModel else { return }
        videoTitleLabel.attributedText = viewModel.createAttributedTitle()
    }
}

// MARK: - TraitEnvironmentAware

extension VideoExplorerTableViewCell: TraitEnvironmentAware {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        traitCollectionChanged(to: traitCollection, from: previousTraitCollection)
    }
    
    func colorAppearanceDidChange(to currentTrait: UITraitCollection, from previousTrait: UITraitCollection?) {
        updateAppearance(with: currentTrait)
    }
}
