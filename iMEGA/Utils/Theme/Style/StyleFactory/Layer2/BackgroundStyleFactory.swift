import Foundation

func createBackgroundStyleFactory(from colorFactory: ColorFactory) -> BackgroundStyleFactory {
    BackgroundStyleFactoryImpl(colorFactory: colorFactory)
}

enum MEGABackgroundStyle {
    case warning
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
        }
    }
}
