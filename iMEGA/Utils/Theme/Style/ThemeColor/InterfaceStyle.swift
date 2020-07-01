import Foundation

enum InterfaceStyle {
    case light
    case dark
}

extension UITraitCollection {

    var theme: InterfaceStyle {
        if #available(iOS 12.0, *) {
            switch userInterfaceStyle {
            case .light: return .light
            case .dark: return .dark
            default: return .light
            }
        }
        return .light
    }
}
