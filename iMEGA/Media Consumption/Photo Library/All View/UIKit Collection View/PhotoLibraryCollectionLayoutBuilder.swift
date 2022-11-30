import Foundation

struct PhotoLibraryCollectionLayoutBuilder {
    let zoomState: PhotoLibraryZoomState
    
    func buildLayout() -> UICollectionViewLayout {
        if zoomState.isSingleColumn {
            return buildSingleColumnLayout()
        } else {
            return buildMultipleColumnsLayout()
        }
    }
    
    private func buildMultipleColumnsLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
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
            configureSupplementaryItems(for: section)
            
            return section
        }
    }
    
    private func buildSingleColumnLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalWidth(0.8))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 4.0
        configureSupplementaryItems(for: section)
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    private func configureSupplementaryItems(for section: NSCollectionLayoutSection) {
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(50)),
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .topLeading
        )
        sectionHeader.pinToVisibleBounds = true
        sectionHeader.zIndex = 2
        section.boundarySupplementaryItems = [sectionHeader]
    }
}
