import UIKit

class PhotoExplorerCollectionCell: UICollectionViewCell {

    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var selectedImageView: UIImageView!

    var viewModel: FileExplorerGridCellViewModel? {
        didSet {
            guard let viewModel = viewModel else { return }
            
            viewModel.loadThumbnail {  [weak self] image, nodeHandle in
                asyncOnMain {
                    guard let self = self, nodeHandle == self.viewModel?.nodeHandle else { return }
                    self.imageView.image = image
                }
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = Asset.Images.Filetypes.image.image
    }
    
    var allowSelection: Bool = false {
        didSet {
            selectedImageView.isHidden = !allowSelection
        }
    }
    
    override var isSelected: Bool {
        didSet {
            selectedImageView.image = isSelected ? Asset.Images.Generic.thumbnailSelected.image : Asset.Images.Login.checkBoxUnselected.image
        }
    }

}
