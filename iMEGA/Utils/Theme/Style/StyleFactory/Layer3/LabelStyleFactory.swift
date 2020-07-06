import Foundation

func createLabelStyleFactory(from colorTheme: InterfaceStyle) -> LabelStyleFactory {
    let colorFactory = createColorFactory(from: colorTheme)
    let textFactory = createTextStyleFactory(from: colorFactory)
    let paragraphStyleFactory = createParagraphStyleFactory()
    return LabelStyleFactoryImpl(textStyleFactory: textFactory, paragraphStyleFactory: paragraphStyleFactory)
}

typealias LabelStyler = (UILabel) -> Void

enum LabelStyle {
    case headline

    // MARK: - Paragraph

    case note1
    case note2
}

protocol LabelStyleFactory {

    func createStyler(of style: LabelStyle) -> LabelStyler
}

private struct LabelStyleFactoryImpl: LabelStyleFactory {

    let textStyleFactory: TextStyleFactory
    let paragraphStyleFactory: ParagraphStyleFactory

    func createStyler(of style: LabelStyle) -> LabelStyler {
        switch style {
        case .headline: return headlineStyler()
        case .note1: return mainNoteStyler()
        case .note2: return subNoteStyler()
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
        let paragraphStyleFactory = self.paragraphStyleFactory
        return { label in
            paragraphStyleFactory.paragraphStyle(of: .naturalAlignedWordWrapping)
                .applied(on: mainNoteTextStyler
                    .applied(on: label))
        }
    }

    private func subNoteStyler() -> LabelStyler {
        let subNoteTextStyler = textStyleFactory.textStyle(of: .caption2)
        let paragraphStyleFactory = self.paragraphStyleFactory
        return { label in
            paragraphStyleFactory.paragraphStyle(of: .naturalAlignedWordWrapping)
                .applied(on: subNoteTextStyler
                    .applied(on: label))
        }
    }
}
