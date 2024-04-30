import Foundation
import MEGAPresentation
import MEGASwift
import MEGAUIKit

extension ItemCollectionViewCell {
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        
        viewModel = nil
        avatarImageView.removeBlurFromView()
        cancellables = nil
    }
    
    @objc func bind(viewModel: ItemCollectionViewCellViewModel) {
        
        self.viewModel = viewModel
        
        viewModel.configureCell()
            
        cancellables = [
            viewModel
                .$isSensitive
                .removeDuplicates()
                .sink { [weak self] in self?.configureBlur(isSensitive: $0) }
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
