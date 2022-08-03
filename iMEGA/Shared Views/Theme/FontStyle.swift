import Foundation
import MEGAUIKit

struct FontStyle: Codable {
    let style: TextStyle
    var weight: Weight? = nil
}

extension FontStyle {
    var value: UIFont {
        guard let weight = weight else {
            return UIFont.preferredFont(forTextStyle: style.value)
        }
        return UIFont.preferredFont(style: style.value,
                                    weight: weight.value)
    }
    
    enum Weight: String, Codable {
        case black
        case bold
        case heavy
        case light
        case medium
        case regular
        case semibold
        case thin
        case ultraLight

        var value: UIFont.Weight {
            switch self {
            case .black: return .black
            case .bold: return .bold
            case .heavy: return .heavy
            case .light: return .light
            case .medium: return .medium
            case .regular: return .regular
            case .semibold: return .semibold
            case .thin: return .thin
            case .ultraLight: return .ultraLight
            }
        }
    }
    
    enum TextStyle: String, Codable {
        case largeTitle
        case title1
        case title2
        case title3
        case headline
        case subheadline
        case body
        case callout
        case footnote
        case caption1
        case caption2
        
        var value: UIFont.TextStyle {
            switch self {
            case .largeTitle: return .largeTitle
            case .title1: return .title1
            case .title2: return .title2
            case .title3: return .title3
            case .headline: return .headline
            case .subheadline: return .subheadline
            case .body: return .body
            case .callout: return .callout
            case .footnote: return .footnote
            case .caption1: return .caption1
            case .caption2: return .caption2
            }
        }
    }
}
