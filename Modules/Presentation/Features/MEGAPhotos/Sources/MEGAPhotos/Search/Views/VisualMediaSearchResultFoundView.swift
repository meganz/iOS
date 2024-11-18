import ContentLibraries
import MEGADesignToken
import MEGADomain
import MEGAPresentation
import SwiftUI

struct VisualMediaSearchResultFoundView: UIViewRepresentable {
    let albums: [AlbumCellViewModel]
    let photos: [PhotoSearchResultItemViewModel]
    
    func makeUIView(context: Context) -> UICollectionView {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: UICollectionViewCompositionalLayout(
                sectionProvider: { sectionIndex, _ in
                    guard let section = context.coordinator.dataSource?.sectionIdentifier(for: sectionIndex) else {
                        return nil
                    }
                    return VisualMediaSearchResultFoundCollectionSectionLayoutFactory()
                        .make(type: section)
                },
                configuration: UICollectionViewCompositionalLayoutConfiguration()
            )
        )
        collectionView.backgroundColor = TokenColors.Background.page
        context.coordinator.configureDataSource(for: collectionView)
        return collectionView
    }
    
    func updateUIView(_ uiView: UICollectionView, context: Context) {
        context.coordinator.reloadData(albums: albums, photos: photos)
    }
    
    func makeCoordinator() -> VisualMediaSearchResultFoundCollectionViewCoordinator {
        VisualMediaSearchResultFoundCollectionViewCoordinator(self)
    }
}
