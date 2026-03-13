import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI

public struct ContentUnavailableViewModel {
    public struct ButtonAction: Action {
        public let id = UUID()
        public let title: String
        public let titleTextColor: Color?
        public let backgroundColor: Color?
        public let image: Image?
        public let handler: () -> Void

        public init(
            title: String,
            titleTextColor: Color? = nil,
            backgroundColor: Color? = nil,
            image: Image?,
            handler: @escaping () -> Void
        ) {
            self.title = title
            self.titleTextColor = titleTextColor
            self.backgroundColor = backgroundColor
            self.image = image
            self.handler = handler
        }
    }

    public struct MenuAction: Action {
        public let id = UUID()
        public let title: String
        public let titleTextColor: Color?
        public let backgroundColor: Color?
        public let actions: [ButtonAction]
        public init(
            title: String,
            titleTextColor: Color? = nil,
            backgroundColor: Color? = nil,
            actions: [ButtonAction]
        ) {
            self.title = title
            self.titleTextColor = titleTextColor
            self.backgroundColor = backgroundColor
            self.actions = actions
        }
    }

    public let image: Image
    public let title: String
    public let subtitle: String?
    public let font: Font
    public let titleTextColor: Color?
    public let actions: [any Action]

    public init(
        image: Image,
        title: String,
        subtitle: String? = nil,
        font: Font,
        titleTextColor: Color?,
        actions: [any Action] = [],
    ) {
        self.image = image
        self.title = title
        self.subtitle = subtitle
        self.font = font
        self.titleTextColor = titleTextColor
        self.actions = actions
    }
}

public extension ContentUnavailableViewModel {
    static var noResults: Self {
        ContentUnavailableViewModel(
            image: MEGAAssets.Image.glassSearch02,
            title: Strings.Localizable.noResults,
            font: .body,
            titleTextColor: TokenColors.Icon.secondary.swiftUI
        )
    }

    static var noDocs: Self {
        ContentUnavailableViewModel(
            image: MEGAAssets.Image.glassFile,
            title: Strings.Localizable.Home.Search.Empty.noDocuments,
            font: .body,
            titleTextColor: TokenColors.Icon.secondary.swiftUI
        )
    }

    static var noAudios: Self {
        ContentUnavailableViewModel(
            image: MEGAAssets.Image.glassAudio,
            title: Strings.Localizable.Home.Search.Empty.noAudio,
            font: .body,
            titleTextColor: TokenColors.Icon.secondary.swiftUI
        )
    }

    static var noVideos: Self {
        ContentUnavailableViewModel(
            image: MEGAAssets.Image.glassVideo,
            title: Strings.Localizable.Home.Search.Empty.noVideos,
            font: .body,
            titleTextColor: TokenColors.Icon.secondary.swiftUI
        )
    }

    static var noImages: Self {
        ContentUnavailableViewModel(
            image: MEGAAssets.Image.glassImage,
            title: Strings.Localizable.Home.Search.Empty.noImages,
            font: .body,
            titleTextColor: TokenColors.Icon.secondary.swiftUI
        )
    }
    static var noPdfs: Self {
        ContentUnavailableViewModel(
            image: MEGAAssets.Image.glassFile,
            title: Strings.Localizable.Home.Search.Empty.noPdfs,
            font: .body,
            titleTextColor: TokenColors.Icon.secondary.swiftUI
        )
    }

    static var noPresentations: Self {
        ContentUnavailableViewModel(
            image: MEGAAssets.Image.glassPlaylist,
            title: Strings.Localizable.Home.Search.Empty.noPresentations,
            font: .body,
            titleTextColor: TokenColors.Icon.secondary.swiftUI
        )
    }

    static var noFolders: Self {
        ContentUnavailableViewModel(
            image: MEGAAssets.Image.glassFolder,
            title: Strings.Localizable.Home.Search.Empty.noFolders,
            font: .body,
            titleTextColor: TokenColors.Icon.secondary.swiftUI
        )
    }

    static var noArchives: Self {
        ContentUnavailableViewModel(
            image: MEGAAssets.Image.glassObjects,
            title: Strings.Localizable.Home.Search.Empty.noArchives,
            font: .body,
            titleTextColor: TokenColors.Icon.secondary.swiftUI
        )
    }

    static var noSpreadSheets: Self {
        ContentUnavailableViewModel(
            image: MEGAAssets.Image.glassFile,
            title: Strings.Localizable.Home.Search.Empty.noSpreadsheets,
            font: .body,
            titleTextColor: TokenColors.Icon.secondary.swiftUI
        )
    }
}
