import Foundation

extension InterfaceStyle {
    var paragraphStyleFactory: some ParagraphStyleFactory {
        ParagraphStyleFactoryImpl()
    }
}

enum MEGAParagraphStyle {

    // MARK: - Multiline Paragraph
    case centerAlignedWideSpacing
    case naturalAlignedWordWrapping

    // MARK: - Singleline Paragraph
    case centered
}

protocol ParagraphStyleFactory {

    func paragraphStyle(of style: MEGAParagraphStyle) -> ParagraphStyle
}

private struct ParagraphStyleFactoryImpl: ParagraphStyleFactory {

    func paragraphStyle(of style: MEGAParagraphStyle) -> ParagraphStyle {
        switch style {
        case .centerAlignedWideSpacing:
            return ParagraphStyle(lineSpacing: 8, alignment: .center)
        case .naturalAlignedWordWrapping:
            return ParagraphStyle(lineBreakMode: .wordWrapping, alignment: .natural)
        case .centered:
            return ParagraphStyle(alignment: .center)
        }
    }
}
