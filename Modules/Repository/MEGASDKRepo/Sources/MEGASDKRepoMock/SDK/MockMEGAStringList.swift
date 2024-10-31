import MEGASdk

public final class MockMEGAStringList: MEGAStringList {
    private var mockSize: Int
    private var mockStrings: [String]
    
    public init(size: Int, strings: [String]) {
        self.mockSize = size
        self.mockStrings = strings
        super.init()
    }
    
    public override var size: Int { mockSize }
    
    public override func string(at index: Int) -> String? {
        guard index >= 0 && index < mockSize else {
            return nil
        }
        return mockStrings[index]
    }
    
    public override func toStringArray() -> [String]? {
        mockStrings.isEmpty ? nil : mockStrings
    }
}
