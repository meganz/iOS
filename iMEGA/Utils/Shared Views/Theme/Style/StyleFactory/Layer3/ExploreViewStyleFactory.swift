import Foundation

enum MEGAExploreViewStyle: Int {
    case images
    case documents
    case audio
    case video
}

struct ExploreViewStyleFactory {
    private let style: MEGAExploreViewStyle
    private let traitCollection: UITraitCollection
    
    private let isRemoveHomeImageFeatureFlagEnabled: Bool
    
    var configuration: ExplorerCardConfiguration {
        switch style {
        case .images:
            return ExplorerCardConfiguration.photosExplorerCardConfiguration(forTraitCollection: traitCollection,
                                                                             isRemoveHomeImageFeatureFlagEnabled: isRemoveHomeImageFeatureFlagEnabled)
        case .documents:
            return ExplorerCardConfiguration.documentsExplorerCardConfiguration(forTraitCollection: traitCollection)
        case .audio:
            return ExplorerCardConfiguration.audioExplorerCardConfiguration(forTraitCollection: traitCollection)
        case .video:
            return ExplorerCardConfiguration.videoExplorerCardConfiguration(forTraitCollection: traitCollection,
                                                                            isRemoveHomeImageFeatureFlagEnabled: isRemoveHomeImageFeatureFlagEnabled)
        }
    }
    
    init(style: MEGAExploreViewStyle, traitCollection: UITraitCollection, isRemoveHomeImageFeatureFlagEnabled: Bool = false) {
        self.style = style
        self.traitCollection = traitCollection
        
        self.isRemoveHomeImageFeatureFlagEnabled = isRemoveHomeImageFeatureFlagEnabled
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
    
    static func photosExplorerCardConfiguration(forTraitCollection traitCollection: UITraitCollection,
                                                isRemoveHomeImageFeatureFlagEnabled: Bool) -> ExplorerCardConfiguration {
        var title = Strings.Localizable.Home.Images.title
        var image = Asset.Images.Home.explorerCardImage.image
        var borderColors = [Colors.SharedViews.Explorer.Gradient.lightBlue.color,
                            Colors.SharedViews.Explorer.Gradient.darkBlue.color]
        if isRemoveHomeImageFeatureFlagEnabled {
            title = Strings.Localizable.Home.Favourites.title
            image = Asset.Images.Home.explorerCardFavourites.image
            borderColors = [Colors.SharedViews.Explorer.Gradient.red.color,
                                Colors.SharedViews.Explorer.Gradient.pink.color]
        }
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
    
    static func videoExplorerCardConfiguration(forTraitCollection traitCollection: UITraitCollection,
                                               isRemoveHomeImageFeatureFlagEnabled: Bool) -> ExplorerCardConfiguration {
        let title = Strings.Localizable.videos
        var iconForegroundImage = Asset.Images.Home.explorerCardVideoPlay.image
        var iconBackgroundImage = Asset.Images.Home.explorerCardVideoFilmStrips.image
        var borderColors = [Colors.SharedViews.Explorer.Gradient.red.color,
                            Colors.SharedViews.Explorer.Gradient.pink.color]
        
        if isRemoveHomeImageFeatureFlagEnabled {
            iconForegroundImage = Asset.Images.Home.explorerCardVideoPlayBlue.image
            iconBackgroundImage = Asset.Images.Home.explorerCardVideoFilmStripsBlue.image
            borderColors = [Colors.SharedViews.Explorer.Gradient.lightBlue.color,
                            Colors.SharedViews.Explorer.Gradient.darkBlue.color]
        }

        return ExplorerCardConfiguration(title: title,
                                         iconForegroundImage: iconForegroundImage,
                                         iconBackgroundImage: iconBackgroundImage,
                                         borderGradientColors: borderColors,
                                         backgroundGradientColors: borderColors,
                                         foregroundGradientColors: (traitCollection.theme == .dark) ? foregroundColorsDark : foregroundColorsLight,
                                         foregroundGradientOpacity: (traitCollection.theme == .dark) ? 0.9 : 1.0)
    }
}
