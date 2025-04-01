import Foundation
import MEGAAppPresentation
import MEGASwift
import MEGAUIKit

extension ItemCollectionViewCell {
    
    open override func prepareForReuse() {
        viewModel = nil
        cancellables = []
        avatarImageView?.image = nil
        avatarImageView?.removeBlurFromView()
        super.prepareForReuse()
    }
    
    @objc func bind(viewModel: ItemCollectionViewCellViewModel) {
        
        self.viewModel = viewModel
        
        viewModel.configureCell()
            
        cancellables = [
            viewModel
                .$isSensitive
                .removeDuplicates()
                .sink { [weak self] in self?.configureBlur(isSensitive: $0) },
            viewModel
                .$thumbnail
                .removeDuplicates()
                .sink { [weak avatarImageView] in avatarImageView?.image = $0 }
        ]
    }
    
    private func configureBlur(isSensitive: Bool) {
                
        guard let viewModel else {
            return
        }
        
        if viewModel.hasThumbnail, isSensitive {
            avatarImageView.addBlurToView(style: .systemUltraThinMaterial)
        } else {
            avatarImageView.removeBlurFromView()
        }
        
        if viewModel.isVideo {
            videoOverlayView.isHidden = true
        }
    }
}
