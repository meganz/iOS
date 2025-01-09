import MEGADomain
import UIKit

@MainActor
public struct AllVideosViewControllerCollectionViewLayoutBuilder {
    public enum ViewType: Equatable {
        case allVideos
        case playlists
        case playlistContent(type: VideoPlaylistEntityType)
        case recentlyWatchedVideos
    }
    
    private let viewType: ViewType
    
    public init(viewType: ViewType) {
        self.viewType = viewType
    }
    
    public func build() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout(
            sectionProvider: { makeCollectionViewLayoutSection(for: $1, viewType: viewType) },
            configuration: UICollectionViewCompositionalLayoutConfiguration()
        )
    }
    
    private func makeCollectionViewLayoutSection(
        for layoutEnvironment: some NSCollectionLayoutEnvironment,
        viewType: ViewType
    ) -> NSCollectionLayoutSection {
        switch viewType {
        case .allVideos, .playlists, .recentlyWatchedVideos:
            allVideosLayoutSection(layoutEnvironment: layoutEnvironment)
        case .playlistContent:
            makeSingleColumnLayout()
        }
    }
    
    private func allVideosLayoutSection(layoutEnvironment: some NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let horizontalSizeClass = layoutEnvironment.traitCollection.horizontalSizeClass
        let verticalSizeClass = layoutEnvironment.traitCollection.verticalSizeClass
        
        switch (horizontalSizeClass, verticalSizeClass) {
        case (.compact, .regular):
            return makeSingleColumnLayout()
        case  (.regular, .compact), (.compact, .compact):
            return makeMultiColumnLayout(columnCount: 2)
        case (.regular, .regular) where isPortrait:
            return makeMultiColumnLayout(columnCount: 2)
        default:
            return makeMultiColumnLayout(columnCount: 3)
        }
    }
    
    private var isPortrait: Bool {
        interfaceOrientation.isPortrait || UIDevice.current.orientation.isPortrait
    }
    
    private var interfaceOrientation: UIInterfaceOrientation {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return .unknown
        }
        return windowScene.interfaceOrientation
    }
    
    private func makeSingleColumnLayout() -> NSCollectionLayoutSection {
        let cellHeight: CGFloat = 80
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(cellHeight))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(cellHeight))
        let group = makeSingleColumnLayoutGroup(from: groupSize, item: item)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 16
        let trailing: CGFloat = switch viewType {
        case .allVideos, .playlistContent, .recentlyWatchedVideos: 12
        case .playlists: 2
        }
        section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 8, bottom: 16, trailing: trailing)
        
        if viewType == .recentlyWatchedVideos {
            section.boundarySupplementaryItems = [ recentlyWatchedVideosSectionHeader() ]
        }
        
        return section
    }
    
    private func makeSingleColumnLayoutGroup(from groupSize: NSCollectionLayoutSize, item: NSCollectionLayoutItem) -> NSCollectionLayoutGroup {
        if #available(iOS 16.0, *) {
            NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, repeatingSubitem: item, count: 1)
        } else {
            NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        }
    }
    
    private func makeMultiColumnLayout(columnCount: Int) -> NSCollectionLayoutSection {
        let cellHeight: CGFloat = 80
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(cellHeight))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(cellHeight))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: columnCount)
        group.interItemSpacing = .fixed(24)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 24
        section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24)
        
        if viewType == .recentlyWatchedVideos {
            section.boundarySupplementaryItems = [ recentlyWatchedVideosSectionHeader() ]
        }
        
        return section
    }
    
    private func recentlyWatchedVideosSectionHeader() -> NSCollectionLayoutBoundarySupplementaryItem {
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(24)
        )
        return NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: RecentlyWatchedVideosSupplementaryElementKind.recentlyWatchedVideosDateSectionHeader.elementKind,
            alignment: .top
        )
    }
}
