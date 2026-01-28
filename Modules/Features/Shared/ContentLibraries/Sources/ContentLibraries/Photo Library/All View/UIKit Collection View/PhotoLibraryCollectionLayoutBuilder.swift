import Foundation
import MEGAAppPresentation
import UIKit

@MainActor
struct PhotoLibraryCollectionLayoutBuilder: Equatable {
    
    let zoomState: PhotoLibraryZoomState
    let bannerType: PhotoLibraryBannerType?
    let isMediaRevampEnabled: Bool
    let contentMode: PhotoLibraryContentMode

    private var isAlbumMode: Bool {
        contentMode == .album
    }
    
    func buildLayout() -> UICollectionViewLayout {
        if isAlbumMode && isMediaRevampEnabled && !zoomState.isSingleColumn {
            return buildMasonryLayout()
        } else if zoomState.isSingleColumn {
            return buildSingleColumnLayout()
        } else {
            return buildMultipleColumnsLayout()
        }
    }
    
    private var layoutConfiguration: UICollectionViewCompositionalLayoutConfiguration {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        var boundaryItems: [NSCollectionLayoutBoundarySupplementaryItem] = []
        
        if let elementKind = PhotoLibrarySupplementaryElementKind.layoutHeader(for: bannerType) {
            boundaryItems.append(configureSupplementaryLayoutHeader(elementKind: elementKind))
        }
        
        if isMediaRevampEnabled {
            boundaryItems.append(configureSupplementaryGlobalZoomHeader())
        }
        
        configuration.boundarySupplementaryItems = boundaryItems
        return configuration
    }
    
    private func buildSingleColumnLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout(
            sectionProvider: { sectionIndex, _ in makeSingleColumnPhotoDateSection(sectionIndex: sectionIndex) },
            configuration: layoutConfiguration)
    }
    
    private func buildMultipleColumnsLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout(
            sectionProvider: { sectionIndex, layoutEnvironment in makeMultiColumnPhotoDateSection(sectionIndex: sectionIndex, layoutEnvironment: layoutEnvironment) },
            configuration: layoutConfiguration)
    }

    private func buildMasonryLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout(
            sectionProvider: { sectionIndex, layoutEnvironment in
                self.makeMasonryPhotoSection(sectionIndex: sectionIndex, layoutEnvironment: layoutEnvironment)
            },
            configuration: layoutConfiguration
        )
    }

    private func makeSingleColumnPhotoDateSection(sectionIndex: Int) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .fractionalWidth(0.8))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, repeatingSubitem: item, count: 1)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 4.0
        
        // Use a placeholder header for the first section when media revamp is enabled
        // This allows tracking when the first section is visible without showing duplicate content
        let isFirstSection = isFirstSection(sectionIndex)
        configureSupplementaryPhotoDateSectionHeader(for: section, isPlaceholder: isFirstSection)
        applyGlobalHeaderTopInset(to: section, isFirstSection: isFirstSection)
        
        return section
    }
    
    private func makeMultiColumnPhotoDateSection(sectionIndex: Int, layoutEnvironment: some NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let contentWidth = layoutEnvironment.container.effectiveContentSize.width
        let spacing: CGFloat = zoomState.scaleFactor == .thirteen ? 0 : 4
        
        let columnCount = zoomState.scaleFactor.rawValue
        let groupHeight = (contentWidth - spacing * CGFloat(columnCount - 1)) / CGFloat(columnCount)
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0 / CGFloat(columnCount)),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .absolute(groupHeight))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, repeatingSubitem: item, count: columnCount)
        group.interItemSpacing = .fixed(spacing)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = spacing
        
        let isFirstSection = isFirstSection(sectionIndex)
        configureSupplementaryPhotoDateSectionHeader(for: section, isPlaceholder: isFirstSection)
        applyGlobalHeaderTopInset(to: section, isFirstSection: isFirstSection)

        return section
    }
    
    private func configureSupplementaryPhotoDateSectionHeader(for section: NSCollectionLayoutSection, isPlaceholder: Bool = false) {
        // Use minimal height for placeholder headers to trigger delegate callbacks without visual presence
        let headerHeight: CGFloat = isPlaceholder ? 0.1 : 50
        
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(headerHeight)),
            elementKind: PhotoLibrarySupplementaryElementKind.photoDateSectionHeader.elementKind,
            alignment: .topLeading
        )
        sectionHeader.pinToVisibleBounds = true
        sectionHeader.zIndex = 2
        section.boundarySupplementaryItems = [sectionHeader]
    }
    
    private func configureSupplementaryLayoutHeader(elementKind: PhotoLibrarySupplementaryElementKind) -> NSCollectionLayoutBoundarySupplementaryItem {
        let bannerHeader = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(isMediaRevampEnabled ? 120 : 80)),
            elementKind: elementKind.elementKind,
            alignment: .topLeading
        )
        bannerHeader.zIndex = 4
        return bannerHeader
    }   
    
    private func configureSupplementaryGlobalZoomHeader() -> NSCollectionLayoutBoundarySupplementaryItem {
        let offset: CGPoint = bannerType != nil ? CGPoint(x: 0, y: PhotoLibrarySupplementaryElementKind.globalHeaderHeight) : .zero
        let globalHeader = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(PhotoLibrarySupplementaryElementKind.globalHeaderHeight)),
            elementKind: PhotoLibrarySupplementaryElementKind.globalZoomHeader.elementKind,
            alignment: .topLeading,
            absoluteOffset: offset
        )
        globalHeader.pinToVisibleBounds = true
        globalHeader.zIndex = 3
        return globalHeader
    }

    private func makeMasonryPhotoSection(
        sectionIndex: Int,
        layoutEnvironment: some NSCollectionLayoutEnvironment
    ) -> NSCollectionLayoutSection {
        let section = MasonrySectionLayoutFactory.makeMasonrySection(layoutEnvironment: layoutEnvironment)
        configureSupplementaryPhotoDateSectionHeader(for: section, isPlaceholder: true)
        
        return section
    }
    
    private func isFirstSection(_ sectionIndex: Int) -> Bool {
        isMediaRevampEnabled && sectionIndex == 0
    }
    
    private func applyGlobalHeaderTopInset(to section: NSCollectionLayoutSection, isFirstSection: Bool) {
        // Add top inset for first section to account for the pinned global header only when banner is displayed
        if isFirstSection && bannerType != nil {
            section.contentInsets.top = PhotoLibrarySupplementaryElementKind.globalHeaderHeight
        }
    }
}
