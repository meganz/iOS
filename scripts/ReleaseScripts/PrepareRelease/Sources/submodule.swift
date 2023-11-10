enum Submodule {
    case sdk
    case chatSDK

    var description: String {
        switch self {
        case .sdk:
            return "MEGASDK"
        case .chatSDK:
            return "MEGAChatSDK"
        }
    }

    var path: String {
        switch self {
        case .sdk:
            return "./Modules/DataSource/MEGASDK/Sources/MEGASDK"
        case .chatSDK:
            return "./Modules/DataSource/MEGAChatSDK/Sources/MEGAChatSDK"
        }
    }
}
