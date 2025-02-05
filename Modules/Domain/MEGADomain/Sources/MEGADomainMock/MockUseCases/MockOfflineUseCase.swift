import Foundation
import MEGADomain
import MEGASwift

public final class MockOfflineUseCase: OfflineUseCaseProtocol, @unchecked Sendable {
    private let _relativePathToDocumentsDirectory: String
    private let offlinesize: UInt64
    
    private(set) var removeItem_calledTimes = 0
    private(set) var removeAllOfflineFiles_calledTimes = 0
    private(set) var removeAllStoredFiles_calledTimes = 0
    
    public var stubbedError: Error?
    public var stubbedRelativePath: String
    
    public init(
        relativePathToDocumentsDirectory: String = "",
        stubbedRelativePath: String = "",
        stubbedError: Error? = nil,
        offlinesize: UInt64 = 0
    ) {
        _relativePathToDocumentsDirectory = relativePathToDocumentsDirectory
        self.stubbedRelativePath = stubbedRelativePath
        self.stubbedError = stubbedError
        self.offlinesize = offlinesize
    }
    
    public func relativePathToDocumentsDirectory(for url: URL) -> String {
        stubbedRelativePath.isEmpty ? _relativePathToDocumentsDirectory : stubbedRelativePath
    }
    
    public func removeItem(at url: URL) throws {
        removeItem_calledTimes += 1
        if let error = stubbedError {
            throw error
        }
    }
    
    public func removeAllOfflineFiles() async {
        removeAllOfflineFiles_calledTimes += 1
    }
    
    public func removeAllStoredFiles() {
        removeAllStoredFiles_calledTimes += 1
    }
    
    public func offlineSize() -> UInt64 {
        offlinesize
    }
}
