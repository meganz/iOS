@testable import MEGA

final class MockLinkManager: MEGALinkManagerProtocol {
    static var adapterLinkURL: URL? {
        get {
            MEGALinkManager.linkURL
        }
        set {
            MEGALinkManager.linkURL = newValue
        }
    }
    
    static func processLinkURL(_ url: URL?) {
        // Do nothing
    }
}
