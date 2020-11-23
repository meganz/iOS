import Foundation

struct Font: Codable {
    typealias FontName = String

    let size: CGFloat
    let weight: FontWeight
}

extension Font {
    var uiFont: UIFont? { UIFont.systemFont(ofSize: size, weight: weight.systemWeight) }
}

extension Font {

    /// Size 17, Bold
    static let title = Font(size: 17, weight: .bold)

    /// Size 15, Bold
    static let titleSmall = Font(size: 15, weight: .bold)

    /// Size 17, Semibold
    static let headline = Font(size: 17, weight: .semibold)

    /// Size 17, Regular
    static let body = Font(size: 17, weight: .regular)

    /// Size 15, Regular
    static let subhead = Font(size: 15, weight: .regular)

    /// Size 15, Medium
    static let subhead2 = Font(size: 15, weight: .medium)

    /// Size 12.5, Semibold
    static let caption1 = Font(size: 12.5, weight: .semibold)

    /// Size 12.5, Regular
    static let caption2 = Font(size: 12.5, weight: .regular)
}

enum FontWeight: String, Codable {
    case black
    case bold
    case heavy
    case light
    case medium
    case regular
    case semibold
    case thin
    case ultraLight

    var systemWeight: UIFont.Weight {
        switch self {
        case .black: return .black
        case .bold: return .bold
        case .heavy: return .heavy
        case .light: return .light
        case .medium: return .medium
        case .regular: return .regular
        case .semibold: return .semibold
        case .thin: return .thin
        case .ultraLight: return .ultraLight
        }
    }
}
