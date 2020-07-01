import Foundation

func createCustomViewStyleFactory(from colorFactory: ColorFactory) -> CustomViewStyleFactory {
    let borderFactory = createBorderStyleFactory(from: colorFactory)
    let backgroundFactory = createBackgroundStyleFactory(from: colorFactory)
    return CustomViewStyleFactoryImpl(borderStyleFactory: borderFactory, backgroundStyleFactory: backgroundFactory)
}

typealias ViewStyler = (UIView) -> Void

enum MEGACustomViewStyle {
    case warning
}

protocol CustomViewStyleFactory {

    func viewStyle(of style: MEGACustomViewStyle) -> ViewStyler
}

private struct CustomViewStyleFactoryImpl: CustomViewStyleFactory {

    let borderStyleFactory: BorderStyleFactory

    let backgroundStyleFactory: BackgroundStyleFactory

    func viewStyle(of style: MEGACustomViewStyle) -> ViewStyler {

        let borderStyleFactory = self.borderStyleFactory
        let backgroundStyleFactory = self.backgroundStyleFactory

        switch style {
        case .warning:
            return { view in
                backgroundStyleFactory.backgroundStyle(of: .warning)
                    .applied(on: CornerStyle.roundCornerStyle
                        .applied(on: borderStyleFactory.borderStyle(of: .warning)
                            .applied(on: view)))
            }
        }
    }
}
