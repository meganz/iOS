import Foundation
import MEGADomain
import MEGASwift

public final class MockOfflineUseCase: OfflineUseCaseProtocol, @unchecked Sendable {
    private let _relativePathToDocumentsDirectory: String
    
    public var removeItem_calledTimes = 0
    public var removeAllOfflineFiles_calledTimes = 0
    public var stubbedError: Error?
    public var stubbedRelativePath: String

    public init(
       relativePathToDocumentsDirectory: String = "",
       stubbedRelativePath: String = "",
       stubbedError: Error? = nil
    ) {
       _relativePathToDocumentsDirectory = relativePathToDocumentsDirectory
       self.stubbedRelativePath = stubbedRelativePath
       self.stubbedError = stubbedError
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
}
