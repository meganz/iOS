import Foundation

extension InterfaceStyle {

    var textStyleFactory: TextStyleFactory {
        TextStyleFactoryImpl(colorFactory: colorFactory)
    }
}

enum MEGATextStyle: Hashable {

    case headline
    case caption1
    case caption2
    case subheadline
    case subheadline2

    case warning
}

protocol TextStyleFactory {

    func textStyle(of textStyle: MEGATextStyle) -> TextStyle
}

private struct TextStyleFactoryImpl: TextStyleFactory {

    let colorFactory: ColorFactory

    func textStyle(of textStyle: MEGATextStyle) -> TextStyle {
        switch textStyle {
        case .headline: return headlineStyle()
        case .subheadline: return subheadlin1Style()
        case .subheadline2: return subheadline2Style()
        case .caption1: return caption1Style()
        case .caption2: return caption2Style()

        case .warning: return warningStyle()
        }
    }

    private func headlineStyle() -> TextStyle {
        TextStyle(font: .headline,
                  color: colorFactory.textColor(.primary))
    }

    private func caption1Style() -> TextStyle {
        TextStyle(font: .caption1,
                  color: colorFactory.textColor(.primary))
    }

    private func caption2Style() -> TextStyle {
        TextStyle(font: .caption2,
                  color: colorFactory.textColor(.primary))
    }

    private func subheadlin1Style() -> TextStyle {
        TextStyle(font: .subhead,
                  color: colorFactory.textColor(.primary))
    }

    private func subheadline2Style() -> TextStyle {
        TextStyle(font: .subhead2,
                  color: colorFactory.textColor(.primary))
    }

    private func warningStyle() -> TextStyle {
        TextStyle(font: .caption1,
                  color: colorFactory.textColor(.warning))
    }
}
