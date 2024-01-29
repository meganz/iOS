import MEGADomain
import MEGAL10n

extension NodeLabelTypeEntity {
    func stringForType() -> String {
        switch self {
        case .red:
            return Strings.Localizable.red
        case .orange:
            return Strings.Localizable.orange
        case .yellow:
            return Strings.Localizable.yellow
        case .green:
            return Strings.Localizable.green
        case .blue:
            return Strings.Localizable.blue
        case .purple:
            return Strings.Localizable.purple
        case .grey:
            return Strings.Localizable.grey
        default:
            return ""
        }
    }
    
    func iconName() -> String {
        switch self {
        case .red:
            return "Red"
        case .orange:
            return "Orange"
        case .yellow:
            return "Yellow"
        case .green:
            return "Green"
        case .blue:
            return "Blue"
        case .purple:
            return "Purple"
        case .grey:
            return "Grey"
        default:
            return ""
        }
    }
}
