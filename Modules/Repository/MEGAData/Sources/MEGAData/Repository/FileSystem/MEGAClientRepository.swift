import Foundation
import MEGADomain

public struct MEGAClientRepository: MEGAClientRepositoryProtocol {
    public static var newRepo: MEGAClientRepository {
        MEGAClientRepository(fileManager: .default)
    }
    
    private let fileManager: FileManager
    
    private enum Constants {
        static let megaclient = "megaclient_statecache13_"
        static let dbextension = ".db"
        static let dropFirstCharactersFromSession = 44
    }
    
    init(fileManager: FileManager) {
        self.fileManager = fileManager
    }
    
    
    public func doesExistNodesOnDemandDatabase(for session: String) -> Bool {
        let applicationSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let cacheSessionName = session.dropFirst(Int(Constants.dropFirstCharactersFromSession))
        let dbname = Constants.megaclient + cacheSessionName + Constants.dbextension
        return fileManager.fileExists(atPath: applicationSupportDirectory?.appendingPathComponent(dbname).path ?? "")
    }
}
