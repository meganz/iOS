import UIKit

@MainActor
struct VisualMediaSearchResultFoundCollectionSectionLayoutFactory {
    func make(type: VisualMediaSearchResults.Section) -> NSCollectionLayoutSection {
        switch type {
        case .albums: makeAlbumsSection()
        case .photos: makePhotosSection()
        }
    }
    
    private func makeAlbumsSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(140),
                                              heightDimension: .estimated(198))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(140),
                                               heightDimension: .estimated(198))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 12.0
        section.orthogonalScrollingBehavior = .continuous
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 0)
        
        section.boundarySupplementaryItems = [makeHeader()]
        return section
    }
    
    private func makePhotosSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .absolute(60))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .absolute(60))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        
        let header = makeHeader()
        header.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        section.boundarySupplementaryItems = [header]
        
        return section
    }
    
    private func makeHeader() -> NSCollectionLayoutBoundarySupplementaryItem {
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                heightDimension: .absolute(38))
        return NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize,
                                                           elementKind: VisualMediaSearchResultSupplementaryElementKind.titleSectionHeader.rawValue,
                                                           alignment: .top)
    }
}
