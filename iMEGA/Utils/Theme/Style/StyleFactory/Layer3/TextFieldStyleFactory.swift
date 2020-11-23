extension InterfaceStyle {

    var textFieldStyleFactory: TextFieldStyleFactory {
        TextFieldStyleFactoryImpl(
            colorFactory: colorFactory,
            textStyleFactory: textStyleFactory,
            cornerStyleFactory: cornerStyleFactory
        )
    }
}

typealias TextFieldStyler = (UITextField) -> Void

enum MEGATextFieldStyle {

    case searchBar
}

protocol TextFieldStyleFactory {

    func styler(of style: MEGATextFieldStyle) -> TextFieldStyler
}

private struct TextFieldStyleFactoryImpl: TextFieldStyleFactory {

    let colorFactory: ColorFactory
    let textStyleFactory: TextStyleFactory
    let cornerStyleFactory: CornerStyleFactory

    func styler(of style: MEGATextFieldStyle) -> TextFieldStyler {
        switch style {
        case .searchBar:
            return { textFiled in
                cornerStyleFactory.cornerStyle(of: .ten).applied(
                    on: colorFactory.textColor(.primary).asTextColorStyle.applied(
                        on: colorFactory.backgroundColor(.searchTextField).asBackgroundColorStyle.applied(
                            on: textStyleFactory.textStyle(of: .body).applied(
                                on: textFiled
                            )
                        )
                    )
                )
            }
        }
    }
}
