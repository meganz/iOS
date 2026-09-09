public enum TransferDirectionEntity: Sendable, CustomStringConvertible {
    case download
    case upload

    public var description: String {
        switch self {
        case .download:
            "download"
        case .upload:
            "upload"
        }
    }
}
