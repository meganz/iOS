import Foundation
import MEGAAppPresentation
import UIKit

@MainActor
struct PhotoLibraryCollectionLayoutBuilder: Equatable {
    
    let zoomState: PhotoLibraryZoomState
    let bannerType: PhotoLibraryBannerType?
    let contentMode: PhotoLibraryContentMode
    let photoGlobalHeaderType: PhotoGlobalHeaderType
    let photoSectionHeaderType: PhotoSectionHeaderType
    
    private var isAlbumMode: Bool {
        contentMode == .album
    }
    
    func buildLayout() -> UICollectionViewLayout {
        if isAlbumMode && AlbumLayoutGate.isMasonryLayoutEnabled && !zoomState.isSingleColumn {
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
        
        if photoGlobalHeaderType != .none {
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
        configureSectionHeader(for: section, isPlaceholder: usesPlaceholderSectionHeader(sectionIndex))
        applyGlobalHeaderTopInset(to: section, sectionIndex: sectionIndex)
        
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
        
        configureSectionHeader(for: section, isPlaceholder: usesPlaceholderSectionHeader(sectionIndex))
        applyGlobalHeaderTopInset(to: section, sectionIndex: sectionIndex)
        
        return section
    }
    
    private func configureSectionHeader(for section: NSCollectionLayoutSection, isPlaceholder: Bool) {
        switch photoSectionHeaderType {
        case .photoDate:
            configureSupplementaryPhotoDateSectionHeader(for: section, isPlaceholder: isPlaceholder)
        case .sort:
            configureSectionSortHeader(for: section)
        case .none:
            break
        }
    }
    
    private func configureSupplementaryPhotoDateSectionHeader(for section: NSCollectionLayoutSection, isPlaceholder: Bool = false) {
        // Use minimal height for placeholder headers to trigger delegate callbacks without visual presence
        let headerHeight: CGFloat = isPlaceholder ? 0.1 : 50
        
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(headerHeight)),
            elementKind: PhotoLibrarySupplementaryElementKind.photoDateSectionHeader.elementKind,
            alignment: .topLeading
        )
        // A global header that renders the date sits above the pinned date headers on purpose, and
        // there is nothing above them at all when there is no global header. But a sort header would
        // simply swallow them, so there the date has to scroll with its section rather than pin.
        sectionHeader.pinToVisibleBounds = photoGlobalHeaderType.showsSectionDate || photoGlobalHeaderType == .none
        sectionHeader.zIndex = 2
        section.boundarySupplementaryItems = [sectionHeader]
    }
    
    private func configureSupplementaryLayoutHeader(elementKind: PhotoLibrarySupplementaryElementKind) -> NSCollectionLayoutBoundarySupplementaryItem {
        let bannerHeader = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(120)),
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
        configureSectionHeader(for: section, isPlaceholder: true)
        return section
    }
    
    private func usesPlaceholderSectionHeader(_ sectionIndex: Int) -> Bool {
        photoGlobalHeaderType.showsSectionDate && sectionIndex == 0
    }
    
    /// Gives the top section back the room the pinned global header takes, which it only needs once a
    /// banner has pushed that header down over the content.
    private func applyGlobalHeaderTopInset(to section: NSCollectionLayoutSection, sectionIndex: Int) {
        guard sectionIndex == 0, photoGlobalHeaderType != .none, bannerType != nil else { return }
        section.contentInsets.top = PhotoLibrarySupplementaryElementKind.globalHeaderHeight
    }
    
    private func configureSectionSortHeader(for section: NSCollectionLayoutSection) {
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(36)),
            elementKind: PhotoLibrarySupplementaryElementKind.layoutSortHeader.elementKind,
            alignment: .topLeading
        )
        sectionHeader.zIndex = 2
        section.boundarySupplementaryItems = [sectionHeader]
    }
}
