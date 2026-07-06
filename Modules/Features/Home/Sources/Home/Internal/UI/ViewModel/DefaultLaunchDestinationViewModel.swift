import MEGAAssets
import MEGADomain
import MEGAL10n
import SwiftUI

@MainActor
final class DefaultLaunchDestinationViewModel: ObservableObject {
    struct Row: Identifiable {
        let destination: LaunchDestinationEntity
        let title: String
        let icon: Image
        var id: LaunchDestinationEntity { destination }
    }

    @Published private(set) var selectedDestination: LaunchDestinationEntity

    let rows: [Row]

    private let useCase: any DefaultLaunchDestinationUseCaseProtocol

    init(useCase: some DefaultLaunchDestinationUseCaseProtocol) {
        self.useCase = useCase
        selectedDestination = useCase.selectedDestination
        rows = LaunchDestinationEntity.allCases.map {
            Row(destination: $0, title: Self.title(for: $0), icon: Self.icon(for: $0))
        }
    }

    func select(_ destination: LaunchDestinationEntity) {
        useCase.setDestination(destination)
        selectedDestination = destination
    }

    private static func title(for destination: LaunchDestinationEntity) -> String {
        switch destination {
        case .home: Strings.Localizable.TabbarTitle.home
        case .drive: Strings.Localizable.TabbarTitle.drive
        case .media: Strings.Localizable.Photos.SearchResults.Media.Section.title
        case .chat: Strings.Localizable.TabbarTitle.chat
        case .sharedItems: Strings.Localizable.sharedItems
        case .favourites: Strings.Localizable.favourites
        case .offline: Strings.Localizable.offline
        }
    }

    private static func icon(for destination: LaunchDestinationEntity) -> Image {
        switch destination {
        case .home: Image(uiImage: MEGAAssets.UIImage.tabBarHome)
        case .drive: Image(uiImage: MEGAAssets.UIImage.tabBarDrive)
        case .media: Image(uiImage: MEGAAssets.UIImage.tabBarPhotos)
        case .chat: Image(uiImage: MEGAAssets.UIImage.tabBarChat)
        case .sharedItems: MEGAAssets.Image.folderUsersMono
        case .favourites: Image(uiImage: MEGAAssets.UIImage.heartOutline)
        case .offline: MEGAAssets.Image.monoCloudOffMediumThinOutline
        }
    }
}
