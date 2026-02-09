import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

enum ShortcutType: CaseIterable, Identifiable {
    case favourites
    case videos
    case offline

    var id: Self { self }

    var title: String {
        switch self {
        case .favourites: Strings.Localizable.favourites
        case .videos: Strings.Localizable.videos
        case .offline: Strings.Localizable.offline
        }
    }

    var icon: Image {
        switch self {
        case .favourites: MEGAAssets.Image.favouritesHomeChip
        case .videos: MEGAAssets.Image.videosHomeChip
        case .offline: MEGAAssets.Image.offlineHomeChip
        }
    }

    var pillViewModel: PillViewModel {
        .init(
            title: title,
            icon: .leading(icon),
            foreground: TokenColors.Text.primary.swiftUI,
            background: TokenColors.Button.secondary.swiftUI,
            font: .subheadline,
            shape: .capsule
        )
    }
}
