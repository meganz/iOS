import Foundation

extension InterfaceStyle {

    var customViewStyleFactory: CustomViewStyleFactory {
        return CustomViewStyleFactoryImpl(borderStyleFactory: borderStyleFactory,
                                          backgroundStyleFactory: backgroundStyleFactory,
                                          cornerStyleFactory: cornerStyleFactory)
    }
}

typealias ViewStyler = (UIView) -> Void

enum MEGACustomViewStyle {
    case warning
}

protocol CustomViewStyleFactory {

    func styler(of style: MEGACustomViewStyle) -> ViewStyler
}

private struct CustomViewStyleFactoryImpl: CustomViewStyleFactory {

    let borderStyleFactory: BorderStyleFactory

    let backgroundStyleFactory: BackgroundStyleFactory

    let cornerStyleFactory: CornerStyleFactory

    func styler(of style: MEGACustomViewStyle) -> ViewStyler {
        let borderStyleFactory = self.borderStyleFactory
        let backgroundStyleFactory = self.backgroundStyleFactory
        let cornerStyleFactory = self.cornerStyleFactory
        switch style {
        case .warning:
            return { view in
                backgroundStyleFactory.backgroundStyle(of: .warning)
                    .applied(on: cornerStyleFactory.cornerStyle(of: .round)
                        .applied(on: borderStyleFactory.borderStyle(of: .warning)
                            .applied(on: view)))
            }
        }
    }
}
