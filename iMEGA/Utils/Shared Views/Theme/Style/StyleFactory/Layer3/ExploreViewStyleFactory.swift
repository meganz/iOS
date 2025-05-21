import Foundation
import MEGAAssets
import MEGAL10n

enum MEGAExploreViewStyle: Int {
    case favourites
    case documents
    case audio
    case video
}

struct ExploreViewStyleFactory {
    private let style: MEGAExploreViewStyle
    private let traitCollection: UITraitCollection
    
    var configuration: ExplorerCardConfiguration {
        switch style {
        case .favourites:
            return ExplorerCardConfiguration.favouritesExplorerCardConfiguration(forTraitCollection: traitCollection)
        case .documents:
            return ExplorerCardConfiguration.documentsExplorerCardConfiguration(forTraitCollection: traitCollection)
        case .audio:
            return ExplorerCardConfiguration.audioExplorerCardConfiguration(forTraitCollection: traitCollection)
        case .video:
            return ExplorerCardConfiguration.videoExplorerCardConfiguration(forTraitCollection: traitCollection)
        }
    }
    
    init(style: MEGAExploreViewStyle, traitCollection: UITraitCollection) {
        self.style = style
        self.traitCollection = traitCollection
    }
}

struct ExplorerCardConfiguration {
    let title: String
    let iconForegroundImage: UIImage?
    let iconBackgroundImage: UIImage?
    let borderGradientColors: [UIColor]
    let backgroundGradientColors: [UIColor]
    let foregroundGradientColors: [UIColor]
    let foregroundGradientOpacity: Float
}

extension ExplorerCardConfiguration {
    private static let foregroundColorsLight = [UIColor(white: 1.0, alpha: 0.95), MEGAAssets.UIColor.whiteFFFFFF]
    private static let foregroundColorsDark = [MEGAAssets.UIColor.explorerForegroundDark, MEGAAssets.UIColor.black000000]
    
    static func favouritesExplorerCardConfiguration(forTraitCollection traitCollection: UITraitCollection) -> ExplorerCardConfiguration {
        let title = Strings.Localizable.Home.Favourites.title
        let image = MEGAAssets.UIImage.explorerCardFavourites
        let borderColors = [MEGAAssets.UIColor.gradientRed,
                            MEGAAssets.UIColor.gradientPink]
        
        return ExplorerCardConfiguration(title: title,
                                         iconForegroundImage: image,
                                         iconBackgroundImage: nil,
                                         borderGradientColors: borderColors,
                                         backgroundGradientColors: borderColors,
                                         foregroundGradientColors: (traitCollection.theme == .dark) ? foregroundColorsDark : foregroundColorsLight,
                                         foregroundGradientOpacity: (traitCollection.theme == .dark) ? 0.9 : 1.0)
    }
    
    static func documentsExplorerCardConfiguration(forTraitCollection traitCollection: UITraitCollection) -> ExplorerCardConfiguration {
        let title = Strings.Localizable.docs
        let image = MEGAAssets.UIImage.explorerCardDocs
        let borderColors = [MEGAAssets.UIColor.explorerDocumentsFirstGradient,
                            MEGAAssets.UIColor.explorerDocumentsSecondGradient]
        
        return ExplorerCardConfiguration(title: title,
                                         iconForegroundImage: image,
                                         iconBackgroundImage: nil,
                                         borderGradientColors: borderColors,
                                         backgroundGradientColors: borderColors,
                                         foregroundGradientColors: (traitCollection.theme == .dark) ? foregroundColorsDark : foregroundColorsLight,
                                         foregroundGradientOpacity: (traitCollection.theme == .dark) ? 0.9 : 1.0)
    }
    
    static func audioExplorerCardConfiguration(forTraitCollection traitCollection: UITraitCollection) -> ExplorerCardConfiguration {
        let title = Strings.Localizable.audio
        let image = MEGAAssets.UIImage.explorerCardAudio
        let borderColors = [MEGAAssets.UIColor.explorerAudioFirstGradient,
                            MEGAAssets.UIColor.explorerAudioSecondGradient]
        return ExplorerCardConfiguration(title: title,
                                         iconForegroundImage: image,
                                         iconBackgroundImage: nil,
                                         borderGradientColors: borderColors,
                                         backgroundGradientColors: borderColors,
                                         foregroundGradientColors: (traitCollection.theme == .dark) ? foregroundColorsDark : foregroundColorsLight,
                                         foregroundGradientOpacity: (traitCollection.theme == .dark) ? 0.9 : 1.0)
    }
    
    static func videoExplorerCardConfiguration(forTraitCollection traitCollection: UITraitCollection) -> ExplorerCardConfiguration {
        let title = Strings.Localizable.videos
        let iconForegroundImage = MEGAAssets.UIImage.explorerCardVideoPlayBlue
        let iconBackgroundImage = MEGAAssets.UIImage.explorerCardVideoFilmStripsBlue
        let borderColors = [MEGAAssets.UIColor.explorerGradientLightBlue,
                            MEGAAssets.UIColor.explorerGradientDarkBlue]

        return ExplorerCardConfiguration(title: title,
                                         iconForegroundImage: iconForegroundImage,
                                         iconBackgroundImage: iconBackgroundImage,
                                         borderGradientColors: borderColors,
                                         backgroundGradientColors: borderColors,
                                         foregroundGradientColors: (traitCollection.theme == .dark) ? foregroundColorsDark : foregroundColorsLight,
                                         foregroundGradientOpacity: (traitCollection.theme == .dark) ? 0.9 : 1.0)
    }
}
