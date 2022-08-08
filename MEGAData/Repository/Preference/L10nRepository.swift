import Foundation
import MEGADomain

struct L10nRepository: L10nRepositoryProtocol {
    var appLanguage: String {
        Bundle.main.preferredLocalizations.first ?? "en"
    }
    
    var deviceRegion: String {
        Locale.autoupdatingCurrent.regionCode ?? Locale.autoupdatingCurrent.identifier
    }
}
