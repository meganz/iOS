import Foundation

public protocol OfflineFilesRepositoryProtocol: RepositoryProtocol, Sendable {
    var offlineURL: URL? { get }
    func createOfflineFile(name: String, for handle: HandleEntity)
}
