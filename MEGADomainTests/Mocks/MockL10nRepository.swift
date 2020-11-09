import Foundation
@testable import MEGA

struct MockL10nRepository: L10nRepositoryProtocol {
    var appLanguage: String = "en"
    
    var deviceRegion: String = "NZ"
}
