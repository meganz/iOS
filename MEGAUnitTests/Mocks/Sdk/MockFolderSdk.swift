@testable import MEGA

final class MockFolderSdk: MEGASdk {
    var apiURL: String?
    var disablepkp: Bool?
    
    override func changeApiUrl(_ apiURL: String, disablepkp: Bool) {
        self.apiURL = apiURL
        self.disablepkp = disablepkp
    }
}

