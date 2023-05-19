import MEGASdk

public final class MockFolderSdk: MEGASdk {
    public var apiURL: String?
    public var disablepkp: Bool?
    
    public override func changeApiUrl(_ apiURL: String, disablepkp: Bool) {
        self.apiURL = apiURL
        self.disablepkp = disablepkp
    }
}
