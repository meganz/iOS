import Foundation

extension InterfaceStyle {

    var backgroundStyleFactory: BackgroundStyleFactory {
        BackgroundStyleFactoryImpl(colorFactory: colorFactory)
    }
}

enum MEGABackgroundStyle {
    case warning
    case homeNavigationBar
    case slideIndicatorContainerView
    case slideIndicator
}

protocol BackgroundStyleFactory {

    func backgroundStyle(of backgroundStyle: MEGABackgroundStyle) -> BackgroundStyle
}

private struct BackgroundStyleFactoryImpl: BackgroundStyleFactory {

    let colorFactory: ColorFactory

    func backgroundStyle(of backgroundStyle: MEGABackgroundStyle) -> BackgroundStyle {
        switch backgroundStyle {
        case .warning:
            return BackgroundStyle(backgroundColor: colorFactory.backgroundColor(.warning))
        case .homeNavigationBar:
            return BackgroundStyle(backgroundColor: colorFactory.backgroundColor(.navigationBar))
        case .slideIndicatorContainerView:
            return BackgroundStyle(backgroundColor: colorFactory.backgroundColor(.primary))
        case .slideIndicator:
            return BackgroundStyle(backgroundColor: colorFactory.backgroundColor(.secondary))
        }
    }
}
