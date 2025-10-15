extension InterfaceStyle {

    var textFieldStyleFactory: some TextFieldStyleFactory {
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

@MainActor
protocol TextFieldStyleFactory {

    func styler(of style: MEGATextFieldStyle) -> TextFieldStyler
}

private struct TextFieldStyleFactoryImpl: TextFieldStyleFactory {

    let colorFactory: any ColorFactory
    let textStyleFactory: any TextStyleFactory
    let cornerStyleFactory: any CornerStyleFactory

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
