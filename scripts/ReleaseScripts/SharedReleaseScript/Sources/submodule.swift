public enum Submodule {
    case sdk
    case chatSDK

    public var description: String {
        switch self {
        case .sdk:
            return "MEGASDK"
        case .chatSDK:
            return "MEGAChatSDK"
        }
    }

    public var path: String {
        switch self {
        case .sdk:
            return "./Modules/DataSource/MEGASDK/Sources/MEGASDK"
        case .chatSDK:
            return "./Modules/DataSource/MEGAChatSDK/Sources/MEGAChatSDK"
        }
    }
}
