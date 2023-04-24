import Foundation
import MEGADomain

public struct L10nRepository: L10nRepositoryProtocol {
    public var appLanguage: String {
        Bundle.main.preferredLocalizations.first ?? "en"
    }
    
    public var deviceRegion: String {
        Locale.autoupdatingCurrent.regionCode ?? Locale.autoupdatingCurrent.identifier
    }
    
    public init() {}
}
