import Foundation

extension InterfaceStyle {

    var attributedTextStyleFactory: AttributedTextStyleFactory {
        let colorFactory = createColorFactory(from: self)
        let textFactory = createTextStyleFactory(from: colorFactory)
        return AttributedTextStyleFactoryImpl(textStyleFactory: textFactory)
    }
}

protocol AttributedTextStyleFactory {

    func styler(of textStyle: AttributedTextStyle) -> TextAttributesStyler
}

private struct AttributedTextStyleFactoryImpl: AttributedTextStyleFactory {

    let textStyleFactory: TextStyleFactory

    func styler(of textStyle: AttributedTextStyle) -> TextAttributesStyler {
        let textStyleFactory = self.textStyleFactory

        switch textStyle {
        case .paragraph:
            return { attributes in
                ParagraphStyle.centerAlignedWideSpacingParagraphStyle
                    .applied(on: textStyleFactory.textStyle(of: .paragraph)
                        .applied(on: attributes))
            }
        case .warning:
            return  { attributes in
               textStyleFactory.textStyle(of: .warning)
                   .applied(on: textStyleFactory.textStyle(of: .emphasized)
                       .applied(on: attributes))
           }
        case .emphasized:
            return { attributes in
                textStyleFactory.textStyle(of: .emphasized).applied(on: attributes)
            }
        }
    }
}
