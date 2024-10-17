import MEGADesignToken
import SwiftUI

struct PhotosBrowserCollectionViewRepresenter: UIViewRepresentable {
    let viewModel: PhotosBrowserCollectionViewModel
    
    func makeCoordinator() -> PhotosBrowserCollectionViewCoordinator {
        PhotosBrowserCollectionViewCoordinator(self)
    }
    
    func makeUIView(context: Context) -> UICollectionView {
        let layout = PhotosBrowserCollectionViewLayout()
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout)
        collectionView.backgroundColor = TokenColors.Background.page
        collectionView.decelerationRate = UIScrollView.DecelerationRate.fast
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        
        context.coordinator.configureDataSource(for: collectionView)
        context.coordinator.updateLayout(layout)
        
        return collectionView
    }
    
    func updateUIView(_ uiView: UICollectionView, context: Context) {
        context.coordinator.updateUI(with: viewModel.library.assets)
    }
}
