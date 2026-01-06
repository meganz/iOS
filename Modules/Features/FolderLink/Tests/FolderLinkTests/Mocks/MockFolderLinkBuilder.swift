import FolderLink

final class MockFolderlinkBuilder: FolderLinkBuilderProtocol, @unchecked Sendable {
    private let result: String
    private(set) var buildCalled = false
    private(set) var link: String?
    private(set) var key: String?
    
    init(result: String = "") {
        self.result = result
    }
    
    func build(link: String, with key: String) async -> String {
        buildCalled = true
        self.link = link
        self.key = key
        return result
    }
}
