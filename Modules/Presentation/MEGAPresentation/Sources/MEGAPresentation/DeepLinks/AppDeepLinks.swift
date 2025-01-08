public enum MEGAApp: Sendable {
    case vpn
    case pwm
    
    public var scheme: String {
        switch self {
        case .vpn: "megavpn://"
        case .pwm: "megapass://"
        }
    }
    
    public var appStoreURL: String {
        "https://apps.apple.com/app/\(id)"
    }
    
    private var id: String {
        switch self {
        case .vpn: "id6456784858"
        case .pwm: "id6468971246"
        }
    }
}
