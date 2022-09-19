import Foundation

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
    private static let foregroundColorsLight = [UIColor(white: 1.0, alpha: 0.95), UIColor.white]
    private static let foregroundColorsDark = [Colors.SharedViews.Explorer.foregroundDark.color, UIColor.black]
    
    static func favouritesExplorerCardConfiguration(forTraitCollection traitCollection: UITraitCollection) -> ExplorerCardConfiguration {
        let title = Strings.Localizable.Home.Favourites.title
        let image = Asset.Images.Home.explorerCardFavourites.image
        let borderColors = [Colors.SharedViews.Explorer.Gradient.red.color,
                            Colors.SharedViews.Explorer.Gradient.pink.color]
        
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
        let image = Asset.Images.Home.explorerCardDocs.image
        let borderColors = [Colors.SharedViews.Explorer.documentsFirstGradient.color,
                            Colors.SharedViews.Explorer.documentsSecondGradient.color]
        
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
        let image = Asset.Images.Home.explorerCardAudio.image
        let borderColors = [Colors.SharedViews.Explorer.audioFirstGradient.color,
                            Colors.SharedViews.Explorer.audioSecondGradient.color]
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
        let iconForegroundImage = Asset.Images.Home.explorerCardVideoPlayBlue.image
        let iconBackgroundImage = Asset.Images.Home.explorerCardVideoFilmStripsBlue.image
        let borderColors = [Colors.SharedViews.Explorer.Gradient.lightBlue.color,
                        Colors.SharedViews.Explorer.Gradient.darkBlue.color]

        return ExplorerCardConfiguration(title: title,
                                         iconForegroundImage: iconForegroundImage,
                                         iconBackgroundImage: iconBackgroundImage,
                                         borderGradientColors: borderColors,
                                         backgroundGradientColors: borderColors,
                                         foregroundGradientColors: (traitCollection.theme == .dark) ? foregroundColorsDark : foregroundColorsLight,
                                         foregroundGradientOpacity: (traitCollection.theme == .dark) ? 0.9 : 1.0)
    }
}
