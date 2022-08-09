import Foundation

extension InterfaceStyle {

    var shadowStyleFactory: ShadowStyleFactory {
        ShadowStyleFactoryImpl()
    }
}

enum MEGAShadowStyle {
    case themeButton(color: ThemeColor)
}

protocol ShadowStyleFactory {
    func shadowStyle(of shadowStyle: MEGAShadowStyle) -> ShadowStyle
}

private struct ShadowStyleFactoryImpl: ShadowStyleFactory {

    func shadowStyle(of shadowStyle: MEGAShadowStyle) -> ShadowStyle {
        switch shadowStyle {
        case .themeButton(let color):
            return ShadowStyle(shadowColor: color,
                               shadowOffset: CGSize(width: 0, height: 1),
                               shadowOpacity: 0.15,
                               shadowRadius: 3)
        }
    }
}
