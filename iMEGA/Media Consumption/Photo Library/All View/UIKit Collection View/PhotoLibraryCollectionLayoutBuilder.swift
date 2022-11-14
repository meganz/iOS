import Foundation

struct PhotoLibraryCollectionLayoutBuilder {
    let zoomState: PhotoLibraryZoomState

    func buildLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { section, layoutEnvironment in
            let contentWidth = layoutEnvironment.container.effectiveContentSize.width
            let spacing: CGFloat = zoomState.scaleFactor == .thirteen ? 0 : 4
            
            let columnCount = zoomState.scaleFactor.rawValue
            let groupHeight = (contentWidth - spacing * CGFloat(columnCount - 1)) / CGFloat(columnCount)
            
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                  heightDimension: .fractionalHeight(1.0))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .absolute(groupHeight))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: columnCount)
            group.interItemSpacing = .fixed(spacing)
            
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = spacing
            
            let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(65)),
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .topLeading
            )
            sectionHeader.pinToVisibleBounds = true
            sectionHeader.zIndex = 2
            section.boundarySupplementaryItems = [sectionHeader]
            
            return section
        }
    }
}
