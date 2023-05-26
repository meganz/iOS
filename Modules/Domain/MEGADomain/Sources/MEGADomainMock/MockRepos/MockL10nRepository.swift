import MEGADomain

public struct MockL10nRepository: L10nRepositoryProtocol {
    public let appLanguage: String
    public let deviceRegion: String
    
    public init(appLanguage: String = "en", deviceRegion: String = "NZ") {
        self.appLanguage = appLanguage
        self.deviceRegion = deviceRegion
    }
    
}
