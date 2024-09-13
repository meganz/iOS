import MEGADesignToken
import MEGAUIKit
import UIKit

class FileExplorerGridCell: UICollectionViewCell {
    
    @IBOutlet private weak var thumbnailImageView: UIImageView!
    @IBOutlet private weak var thumbnailPlayImageView: UIImageView!
    @IBOutlet private weak var thumbnailIconImageView: UIImageView!
    @IBOutlet private weak var selectImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var infoLabel: UILabel!
    @IBOutlet private weak var moreButton: UIButton!
    
    var viewModel: FileExplorerGridCellViewModel? {
        didSet {
            configViewModel()
        }
    }
    
    private func configViewModel() {
        guard let viewModel = viewModel else {
            return
        }
        
        viewModel.loadThumbnail {  [weak self] image, nodeHandle in
            asyncOnMain {
                guard let self = self, nodeHandle == self.viewModel?.nodeHandle else { return }
                
                let thumbnailImageView = viewModel.hasThumbnail ? self.thumbnailImageView : self.thumbnailIconImageView
                thumbnailImageView?.image = image
                thumbnailImageView?.isHidden = false
            }
        }
        
        if viewModel.isTakenDown,
           let takenDownAttributedText = NSAttributedString.mnz_attributedString(from: UIImage.isTakedown, fontCapHeight: nameLabel.font.capHeight) {
            let mutableAttributedText = NSMutableAttributedString(string: viewModel.name)
            mutableAttributedText.append(takenDownAttributedText)
            nameLabel.attributedText = mutableAttributedText
        } else {
            nameLabel.text = viewModel.name
            infoLabel.text = viewModel.sizeDescription
        }
        
        thumbnailPlayImageView.isHidden = !viewModel.isVideo
        
        allowsSelection = viewModel.allowsSelection
        markSelection = viewModel.markSelection
        setupAppearance(with: traitCollection)
    }
    
    private var allowsSelection: Bool = false {
        didSet {
            selectImageView.isHidden = !allowsSelection
            moreButton.isHidden = allowsSelection
        }
    }
    
    private var markSelection: Bool = false {
        didSet {
            selectImageView.image = markSelection ? UIImage.thumbnailSelected : UIImage.checkBoxUnselected
            updateBorderColor()
        }
    }

    private func updateBorderColor() {
        markSelection ? TokenColors.Support.success : TokenColors.Border.strong
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailIconImageView.image = nil
        thumbnailIconImageView.isHidden = true
        thumbnailImageView.image = nil
        thumbnailImageView.isHidden = false
    }
    
    @IBAction private func moreButtonTapped(_ button: UIButton) {
        viewModel?.moreButtonTapped(button)
    }
    
    private func setupAppearance(with trait: UITraitCollection) {
        switch trait.theme {
        case .dark:
            thumbnailImageView.backgroundColor = MEGAAppColor.Black._1C1C1E.uiColor
        default:
            thumbnailImageView.backgroundColor = MEGAAppColor.White._F7F7F7.uiColor
        }
        updateBorderColor()
    }
}

extension FileExplorerGridCell: FileExplorerGridCellViewModelDelegate {
    func onUpdateAllowsSelection() {
        allowsSelection = viewModel?.allowsSelection ?? false
    }
    
    func onUpdateMarkSelection() {
        markSelection = viewModel?.markSelection ?? false
    }
    
    func updateSelection() {
        onUpdateAllowsSelection()
        onUpdateMarkSelection()
    }
}

// MARK: - TraitEnvironmentAware

extension FileExplorerGridCell: TraitEnvironmentAware {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        traitCollectionChanged(to: traitCollection, from: previousTraitCollection)
    }
    
    func colorAppearanceDidChange(to currentTrait: UITraitCollection, from previousTrait: UITraitCollection?) {
        setupAppearance(with: currentTrait)
    }
}
