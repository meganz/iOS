import Foundation

extension InterfaceStyle {

    var textStyleFactory: TextStyleFactory {
        TextStyleFactoryImpl()
    }
}

enum MEGATextStyle: Hashable {

    case title
    case titleMedium
    case titleSmall

    case headline

    case caption1
    case caption2

    case subheadline
    case subheadline2

    case body

    case subtitle1

    case warning
}

protocol TextStyleFactory {

    func textStyle(of textStyle: MEGATextStyle) -> TextStyle
}

private struct TextStyleFactoryImpl: TextStyleFactory {

    func textStyle(of textStyle: MEGATextStyle) -> TextStyle {
        switch textStyle {
        case .title: return TextStyle(font: .title)
        case .titleMedium: return TextStyle(font: .titleMedium)
        case .titleSmall: return TextStyle(font: .titleSmall)

        case .headline: return TextStyle(font: .headline)
        case .subheadline: return TextStyle(font: .subhead)
        case .subheadline2: return TextStyle(font: .subhead2)

        case .caption1: return TextStyle(font: .caption1)
        case .caption2: return TextStyle(font: .caption2)

        case .body: return TextStyle(font: .body)

        case .subtitle1: return TextStyle(font: .subtitle1)

        case .warning: return TextStyle(font: .caption1)
        }
    }
}
