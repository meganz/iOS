import Foundation
import MEGAAppSDKRepo
import MEGASdk

public struct MockDirectoryProvider: DirectoryProvidingProtocol {
    private let containerURL: URL?
    private let offlineURL: URL?
    private let downloadsURL: URL?
    private let uploadsURL: URL?
    private let sharedURL: URL?
    private let containerError: MEGAError
    private let downloadsError: MEGAError
    private let uploadsError: MEGAError
    
    private let domain = "MockDirectoryProvider"
    
    public init(
        containerURL: URL? = nil,
        offlineURL: URL? = nil,
        downloadsURL: URL? = nil,
        uploadsURL: URL? = nil,
        sharedURL: URL? = nil,
        containerError: MEGAError = .init(),
        downloadsError: MEGAError = .init(),
        uploadsError: MEGAError = .init()
    ) {
        self.containerURL = containerURL
        self.offlineURL = offlineURL
        self.downloadsURL = downloadsURL
        self.uploadsURL = uploadsURL
        self.sharedURL = sharedURL
        self.containerError = containerError
        self.downloadsError = downloadsError
        self.uploadsError = uploadsError
    }
    
    public func urlForSharedSandboxCacheDirectory(_ directory: String) throws -> URL {
        guard let containerURL else { throw containerError }
        return containerURL.appendingPathComponent(directory, isDirectory: true)
    }
    
    public func pathForOffline() -> URL? {
        offlineURL
    }
    
    public func downloadsDirectory() throws -> URL {
        guard let downloadsURL else { throw downloadsError }
        return downloadsURL
    }
    
    public func uploadsDirectory() throws -> URL {
        guard let uploadsURL else { throw uploadsError }
        return uploadsURL
    }
    
    public func groupSharedURL() -> URL? {
        sharedURL
    }
}
