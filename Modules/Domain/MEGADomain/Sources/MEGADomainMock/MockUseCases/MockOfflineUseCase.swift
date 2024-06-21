import Foundation
import MEGADomain

public struct MockOfflineUseCase: OfflineUseCaseProtocol {
    private let _relativePathToDocumentsDirectory: String

    public init(_relativePathToDocumentsDirectory: String = "") {
        self._relativePathToDocumentsDirectory = _relativePathToDocumentsDirectory
    }
    public func relativePathToDocumentsDirectory(for url: URL) -> String {
        _relativePathToDocumentsDirectory
    }
    
    public func removeItem(at url: URL) throws {}
}
