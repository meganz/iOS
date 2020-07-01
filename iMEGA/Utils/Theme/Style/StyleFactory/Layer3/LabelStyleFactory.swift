import Foundation

func createLabelStyleFactory(from colorTheme: InterfaceStyle) -> LabelStyleFactory {
    let colorFactory = createColorFactory(from: colorTheme)
    let textFactory = textStyleFactory(from: colorFactory)
    return LabelStyleFactoryImpl(textStyleFactory: textFactory)
}

typealias LabelStyler = (UILabel) -> Void

enum LabelStyle {
    case headline
    case noteMain
    case noteSub
}

protocol LabelStyleFactory {

    func createStyler(of style: LabelStyle) -> LabelStyler
}

private struct LabelStyleFactoryImpl: LabelStyleFactory {

    let textStyleFactory: TextStyleFactory

    func createStyler(of style: LabelStyle) -> LabelStyler {
        switch style {
        case .headline: return headlineStyler()
        case .noteMain: return mainNoteStyler()
        case .noteSub: return subNoteStyler()
        }
    }

    private func headlineStyler() -> LabelStyler {
        let headlineTextStyler = textStyleFactory.textStyle(of: .headline)
        return { label in
            headlineTextStyler.applied(on: label)
        }
    }

    private func mainNoteStyler() -> LabelStyler {
        let mainNoteTextStyler = textStyleFactory.textStyle(of: .caption1)
        return { label in
            ParagraphStyle.multilineWordWrappingNaturalAlignedParagraphStyle
                .applied(on: mainNoteTextStyler
                    .applied(on: label))
        }
    }

    private func subNoteStyler() -> LabelStyler {
        let subNoteTextStyler = textStyleFactory.textStyle(of: .caption2)
        return { label in
            ParagraphStyle.multilineWordWrappingNaturalAlignedParagraphStyle
                .applied(on: subNoteTextStyler
                    .applied(on: label))
        }
    }
}
