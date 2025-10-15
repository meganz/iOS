public enum BannerErrorEntity: Error, Sendable {
    case unexpected
    case userSessionTimeout
    case `internal`
    case resourceDoesNotExist
}
