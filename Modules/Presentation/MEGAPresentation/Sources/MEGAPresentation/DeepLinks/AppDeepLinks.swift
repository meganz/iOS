public enum MEGAApp: Sendable {
    case vpn
    
    public var scheme: String {
        switch self {
        case .vpn: "megavpn://"
        }
    }
    
    public var appStoreURL: String {
        switch self {
        case .vpn: "https://apps.apple.com/app/\(id)"
        }
    }
    
    private var id: String {
        switch self {
        case .vpn: "id6456784858"
        }
    }
}
