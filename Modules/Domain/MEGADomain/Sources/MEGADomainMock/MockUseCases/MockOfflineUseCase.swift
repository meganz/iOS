import Foundation
import MEGADomain
import MEGASwift

public final class MockOfflineUseCase: OfflineUseCaseProtocol, @unchecked Sendable {
    private let _relativePathToDocumentsDirectory: String
    private var _offlineSize: UInt64
    
    private(set) var removeItem_calledTimes = 0
    private(set) var removeAllOfflineFiles_calledTimes = 0
    private(set) var removeAllStoredFiles_calledTimes = 0
    
    public var stubbedError: Error?
    public var stubbedRelativePath: String
    
    public init(
        relativePathToDocumentsDirectory: String = "",
        stubbedRelativePath: String = "",
        stubbedError: Error? = nil,
        offlineSize: UInt64 = 0
    ) {
        _relativePathToDocumentsDirectory = relativePathToDocumentsDirectory
        self.stubbedRelativePath = stubbedRelativePath
        self.stubbedError = stubbedError
        _offlineSize = offlineSize
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
        _offlineSize = 0
        removeAllOfflineFiles_calledTimes += 1
    }
    
    public func removeAllStoredFiles() {
        _offlineSize = 0
        removeAllStoredFiles_calledTimes += 1
    }
    
    public func offlineSize() -> UInt64 {
        _offlineSize
    }
}
