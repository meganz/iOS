import Foundation
import UIKit

@MainActor
struct PhotoLibraryCollectionLayoutBuilder: Equatable {
    
    let zoomState: PhotoLibraryZoomState
    let enableCameraUploadBannerVisible: Bool
    
    func buildLayout() -> UICollectionViewLayout {
        if zoomState.isSingleColumn {
            return buildSingleColumnLayout()
        } else {
            return buildMultipleColumnsLayout()
        }
    }
    
    private var layoutConfiguration: UICollectionViewCompositionalLayoutConfiguration {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        if enableCameraUploadBannerVisible {
            configuration.boundarySupplementaryItems = [ configureSupplementaryLayoutHeader() ]
        }
        return configuration
    }
    
    private func buildSingleColumnLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout(
            sectionProvider: { _, _ in makeSingleColumnPhotoDateSection() },
            configuration: layoutConfiguration)
    }
    
    private func buildMultipleColumnsLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout(
            sectionProvider: { _, layoutEnvironment in makeMultiColumnPhotoDateSection(layoutEnvironment: layoutEnvironment) },
            configuration: layoutConfiguration)
    }
    
    private func makeSingleColumnPhotoDateSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalWidth(0.8))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 4.0
        configureSupplementaryPhotoDateSectionHeader(for: section)
        return section
    }
    
    private func makeMultiColumnPhotoDateSection(layoutEnvironment: some NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
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
        configureSupplementaryPhotoDateSectionHeader(for: section)
        
        return section
    }
    
    private func makeBannerSection() -> NSCollectionLayoutSection {
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .estimated(80))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = itemSize
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)
        group.interItemSpacing = .fixed(0)
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .zero
        return section
    }
    
    private func configureSupplementaryPhotoDateSectionHeader(for section: NSCollectionLayoutSection) {
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(50)),
            elementKind: PhotoLibrarySupplementaryElementKind.photoDateSectionHeader.elementKind,
            alignment: .topLeading
        )
        sectionHeader.pinToVisibleBounds = true
        sectionHeader.zIndex = 2
        section.boundarySupplementaryItems = [sectionHeader]
    }
    
    private func configureSupplementaryLayoutHeader() -> NSCollectionLayoutBoundarySupplementaryItem {
        NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(80)),
            elementKind: PhotoLibrarySupplementaryElementKind.layoutHeader.elementKind,
            alignment: .topLeading
        )
    }
}
