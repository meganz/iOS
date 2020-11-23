
import UIKit

class FileExplorerGridCell: UICollectionViewCell {
    
    @IBOutlet private weak var thumbnailImageView: UIImageView!
    @IBOutlet private weak var thumbnailPlayImageView: UIImageView!
    @IBOutlet private weak var thumbnailIconImageView: UIImageView!
    @IBOutlet private weak var selectImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var moreButton: UIButton!
    
    var viewModel: FileExplorerGridCellViewModel? {
        didSet {
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
                fromImageNamed: "isTakedown",
                fontCapHeight: nameLabel.font.capHeight
               ) {
                let mutableAttributedText = NSMutableAttributedString(string: viewModel.name)
                mutableAttributedText.append(takenDownAttributedText)
                nameLabel.attributedText = mutableAttributedText
            } else {
                nameLabel.text = viewModel.name
            }
            
            thumbnailPlayImageView.isHidden = !viewModel.isVideo
            
            allowsSelection = viewModel.allowsSelection
            markSelection = viewModel.markSelection
        }
    }
    
    private var allowsSelection: Bool = false {
        didSet {
            selectImageView.isHidden = !allowsSelection
        }
    }
    
    private var markSelection: Bool = false {
        didSet {
            selectImageView.image = UIImage(named: markSelection ? "thumbnail_selected" : "checkBoxUnselected")
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailIconImageView.image = nil
        thumbnailIconImageView.isHidden = true
        thumbnailImageView.image = nil
        thumbnailImageView.isHidden = true
    }
    
    @IBAction private func moreButtonTapped(_ button: UIButton) {
        viewModel?.moreButtonTapped(button)
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
