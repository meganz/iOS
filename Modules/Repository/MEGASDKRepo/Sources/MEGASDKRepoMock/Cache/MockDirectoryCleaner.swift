import Foundation
import MEGASDKRepo

public final class MockDirectoryCleaner: DirectoryCleaningProtocol, @unchecked Sendable {
    public private(set) var removeFolderContents_calledTimes = 0
    public private(set) var removeFolderContentsRecursively_calledTimes = 0
    public private(set) var removeItemAtURL_calledTimes = 0
    
    public init() {}
    
    public func removeFolderContents(
        at url: URL,
        containing substring: String?,
        recursive: Bool,
        withExtension fileExtension: String?
    ) throws {
        removeFolderContents_calledTimes += 1
    }
    
    public func removeFolderContentsRecursively(
        at url: URL,
        containing substring: String?,
        withExtension fileExtension: String?
    ) throws {
        removeFolderContentsRecursively_calledTimes += 1
    }
    
    public func removeItemAtURL(_ url: URL?) throws {
        removeItemAtURL_calledTimes += 1
    }
}
