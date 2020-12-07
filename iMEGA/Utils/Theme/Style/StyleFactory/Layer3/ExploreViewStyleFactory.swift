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
    
    var configuration: ExplorerCardConfiguration {
        switch style {
        case .images:
            return ExplorerCardConfiguration.photosExplorerCardConfiguration(forTraitCollection: traitCollection)
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
    let image: UIImage
    let borderGradientColors: [UIColor]
    let backgroundGradientColors: [UIColor]
    let foregroundGradientColors: [UIColor]
}

extension ExplorerCardConfiguration {
    private static let foregroundColorsLight = [UIColor(white: 1.0, alpha: 0.95), UIColor.white]
    private static let foregroundColorsDark = [UIColor.mnz_(fromHexString: "#1C1C1F"), UIColor.black]
    
    static func photosExplorerCardConfiguration(forTraitCollection traitCollection: UITraitCollection) -> ExplorerCardConfiguration {
        let title = NSLocalizedString("Photos", comment: "New Home: Explorer view cards - Photos")
        let image = UIImage()
        let borderColors = [UIColor.mnz_(fromHexString: "#1695F8"), UIColor.mnz_(fromHexString: "#0054C3")]
        return ExplorerCardConfiguration(title: title,
                                         image: image,
                                         borderGradientColors: borderColors,
                                         backgroundGradientColors: borderColors,
                                         foregroundGradientColors: (traitCollection.theme == .dark) ? foregroundColorsDark : foregroundColorsLight)
    }
    
    static func documentsExplorerCardConfiguration(forTraitCollection traitCollection: UITraitCollection) -> ExplorerCardConfiguration {
        let title = NSLocalizedString("Docs", comment: "Home Screen: Explorer view card title - Documents")
        let image = UIImage()
        let borderColors = [UIColor.mnz_(fromHexString: "#FEB800"), UIColor.mnz_(fromHexString: "#FE8601")]
        return ExplorerCardConfiguration(title: title,
                                         image: image,
                                         borderGradientColors: borderColors,
                                         backgroundGradientColors: borderColors,
                                         foregroundGradientColors: (traitCollection.theme == .dark) ? foregroundColorsDark : foregroundColorsLight)
    }
    
    static func audioExplorerCardConfiguration(forTraitCollection traitCollection: UITraitCollection) -> ExplorerCardConfiguration {
        let title = NSLocalizedString("Audio", comment: "New Home: Explorer view cards - Audio")
        let image = UIImage()
        let borderColors = [UIColor.mnz_(fromHexString: "#2BA6DE"), UIColor.mnz_(fromHexString: "#00C398")]
        return ExplorerCardConfiguration(title: title,
                                         image: image,
                                         borderGradientColors: borderColors,
                                         backgroundGradientColors: borderColors,
                                         foregroundGradientColors: (traitCollection.theme == .dark) ? foregroundColorsDark : foregroundColorsLight)
    }
    
    static func videoExplorerCardConfiguration(forTraitCollection traitCollection: UITraitCollection) -> ExplorerCardConfiguration {
        let title = NSLocalizedString("Videos", comment: "New Home: Explorer view cards - Videos")
        let image = UIImage()
        let borderColors = [UIColor.mnz_(fromHexString: "#EB1C5C"), UIColor.mnz_(fromHexString: "#E301CA")]
        return ExplorerCardConfiguration(title: title,
                                         image: image,
                                         borderGradientColors: borderColors,
                                         backgroundGradientColors: borderColors,
                                         foregroundGradientColors: (traitCollection.theme == .dark) ? foregroundColorsDark : foregroundColorsLight)
    }
}
