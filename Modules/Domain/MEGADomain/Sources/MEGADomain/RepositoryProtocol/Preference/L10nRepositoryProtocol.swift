public protocol L10nRepositoryProtocol: Sendable {
    var appLanguage: String { get }
    var deviceRegion: String { get }
}
