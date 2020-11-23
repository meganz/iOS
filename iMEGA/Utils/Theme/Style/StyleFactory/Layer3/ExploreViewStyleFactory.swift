import Foundation


extension InterfaceStyle {

    var exploreViewStyleFactory: ExploreViewStyleFactory {
        ExploreViewStyleFactoryImpl(colorFactory: colorFactory)
    }
}

enum MEGAExploreViewStyle: Int {
    case images
    case documents
    case audio
    case video
}

typealias ExploreViewStyler = (ExploreView) -> Void


protocol ExploreViewStyleFactory {

    func styler(of style: MEGAExploreViewStyle) -> ExploreViewStyler
}

private struct ExploreViewStyleFactoryImpl: ExploreViewStyleFactory {

    let colorFactory: ColorFactory

    func styler(of style: MEGAExploreViewStyle) -> ExploreViewStyler {
        switch style {
        case .images:
            let image = createImage(of: style)
            let gradientConfiguration = createGradientConfiguration(
                startColor: colorFactory.gradient(.exploreImagesStart),
                endColor: colorFactory.gradient(.exploreImagesEnd)
            )
            return { exploreView in
                exploreView.setImage(image, for: .normal)
                exploreView.gradientBackgroundConfiguration = gradientConfiguration
            }
            
        case .documents:
            let image = createImage(of: style)
            let gradientConfiguration = createGradientConfiguration(
                startColor: colorFactory.gradient(.exploreDocumentsStart),
                endColor: colorFactory.gradient(.exploreDocumentsEnd)
            )
            return { exploreView in
                exploreView.setImage(image, for: .normal)
                exploreView.gradientBackgroundConfiguration = gradientConfiguration
            }
            
        case .audio:
            let image = createImage(of: style)
            let gradientConfiguration = createGradientConfiguration(
                startColor: colorFactory.gradient(.exploreAudioStart),
                endColor: colorFactory.gradient(.exploreAudioEnd)
            )
            return { exploreView in
                exploreView.setImage(image, for: .normal)
                exploreView.gradientBackgroundConfiguration = gradientConfiguration
            }
            
        case .video:
            let image = createImage(of: style)
            let gradientConfiguration = createGradientConfiguration(
                startColor: colorFactory.gradient(.exploreVideoStart),
                endColor: colorFactory.gradient(.exploreVideoEnd)
            )
            return { exploreView in
                exploreView.setImage(image, for: .normal)
                exploreView.gradientBackgroundConfiguration = gradientConfiguration
            }
        }
    }
    
    private func createGradientConfiguration(startColor: Color, endColor: Color) -> GradientConfiguration {
       return GradientConfiguration(steps: [
          .init(color: startColor.uiColor.cgColor, startPoint: CGPoint(x: 0, y: 1)),
          .init(color: endColor.uiColor.cgColor, startPoint: CGPoint(x: 1, y: 0))
      ])
    }
    
    private func createImage(of style: MEGAExploreViewStyle) -> UIImage? {
        switch style {
        case .images:       return UIImage(named: "imagesCard")
        case .documents:    return UIImage(named: "docsCard")
        case .audio:        return UIImage(named: "audioCard")
        case .video:        return UIImage(named: "videoCard")
        }
    }
}
