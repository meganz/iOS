import Foundation

extension InterfaceStyle {

    var paragraphStyleFactory: ParagraphStyleFactory {
        ParagraphStyleFactoryImpl()
    }
}

enum MEGAParagraphStyle {
    case centerAlignedWideSpacing
    case naturalAlignedWordWrapping
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
        }
    }
}
