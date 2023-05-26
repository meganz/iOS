import Foundation

public protocol OfflineFilesRepositoryProtocol: RepositoryProtocol {
    var offlineURL: URL? { get }
    func createOfflineFile(name: String, for handle: HandleEntity)
}
