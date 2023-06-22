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
           let takenDownAttributedText = NSAttributedString.mnz_attributedString(
            fromImageNamed: Asset.Images.Generic.isTakedown.name,
            fontCapHeight: nameLabel.font.capHeight
           ) {
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
            selectImageView.image = markSelection ? Asset.Images.Generic.thumbnailSelected.image : Asset.Images.Login.checkBoxUnselected.image
            if markSelection {
                self.borderColor = #colorLiteral(red: 0, green: 0.6588235294, blue: 0.5254901961, alpha: 1)
            } else {
                self.borderColor = traitCollection.theme == .dark ? #colorLiteral(red: 0.3294117647, green: 0.3294117647, blue: 0.3450980392, alpha: 0.65) : #colorLiteral(red: 0.968627451, green: 0.968627451, blue: 0.968627451, alpha: 1)
            }
        }
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
            self.borderColor = #colorLiteral(red: 0.3294117647, green: 0.3294117647, blue: 0.3450980392, alpha: 0.65)
            thumbnailImageView.backgroundColor = #colorLiteral(red: 0.1098039216, green: 0.1098039216, blue: 0.1176470588, alpha: 1)
        default:
            self.borderColor = #colorLiteral(red: 0.968627451, green: 0.968627451, blue: 0.968627451, alpha: 1)
            thumbnailImageView.backgroundColor = #colorLiteral(red: 0.968627451, green: 0.968627451, blue: 0.968627451, alpha: 1)
        }
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

// MARK: - TraitEnviromentAware

extension FileExplorerGridCell: TraitEnviromentAware {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        traitCollectionChanged(to: traitCollection, from: previousTraitCollection)
    }

    func colorAppearanceDidChange(to currentTrait: UITraitCollection, from previousTrait: UITraitCollection?) {
        setupAppearance(with: currentTrait)
    }
}
