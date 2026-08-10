import FileLink

final class MockFileLinkBuilder: FileLinkBuilderProtocol, @unchecked Sendable {
    private(set) var buildCalledArguments: [(link: String, key: String)] = []

    private let result: String

    init(result: String = "") {
        self.result = result
    }

    func build(link: String, with key: String) async -> String {
        buildCalledArguments.append((link, key))
        return result
    }
}
