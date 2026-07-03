import Foundation
import MEGADomain

public struct CopyDataBasesRepository: CopyDataBasesRepositoryProtocol {
    public static var newRepo: CopyDataBasesRepository {
        CopyDataBasesRepository(fileManager: FileManager.default)
    }

    /// Variant whose freshness decision considers only the node statecache DB (excluding
    /// `prefs`/`status`/`transfers`/`karere`). Used by the File Provider extension, where the SDK's
    /// `prefs.db` — created before the copy runs — would otherwise make the local dir look newer than a
    /// valid App Group seed and skip the copy. Other consumers keep the original matching via `newRepo`.
    public static var nodeDatabaseGatedRepo: CopyDataBasesRepository {
        CopyDataBasesRepository(fileManager: FileManager.default, gatesFreshnessOnNodeDatabaseOnly: true)
    }
    
    let fileManager: FileManager
    private let gatesFreshnessOnNodeDatabaseOnly: Bool
    
    enum Constants {
        static let groupIdentifier = "group.mega.ios"
        static let extensionGroupSupportFolder = "GroupSupport"
    }
    
    public init(fileManager: FileManager, gatesFreshnessOnNodeDatabaseOnly: Bool = false) {
        self.fileManager = fileManager
        self.gatesFreshnessOnNodeDatabaseOnly = gatesFreshnessOnNodeDatabaseOnly
    }
    
    public func applicationSupportDirectoryURL(completion: @escaping (Result<URL, CopyDataBasesErrorEntity>) -> Void) {
        do {
            let applicationSupportDirectoryURL = try fileManager.url(for: FileManager.SearchPathDirectory.applicationSupportDirectory, in: FileManager.SearchPathDomainMask.userDomainMask, appropriateFor: nil, create: true)
            completion(.success(applicationSupportDirectoryURL))
        } catch {
            completion(.failure(.fileManager(step: .applicationSupportDirectory, fileName: nil, underlyingError: error)))
        }
    }
    
    public func groupSupportDirectoryURL(completion: @escaping (Result<URL, CopyDataBasesErrorEntity>) -> Void) {
        guard let groupSupportURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: Constants.groupIdentifier)?.appendingPathComponent(
            Constants.extensionGroupSupportFolder) else {
            completion(.failure(.fileManager(step: .groupSupportDirectory, fileName: nil, underlyingError: nil)))
            return
        }
        
        completion(.success(groupSupportURL))
    }
    
    public func newestModificationDateOfItemAt(url: URL, completion: @escaping (Result<Date, CopyDataBasesErrorEntity>) -> Void) {
        var newestDate = Date(timeIntervalSince1970: 0)

        contentsOfItemAt(url: url) { (result) in
            switch result {
            case .success(let pathContent):
                for filename in pathContent where matchesFreshnessRelevantFile(filename) {
                    do {
                        let date = try fileManager.attributesOfItem(atPath: url.appendingPathComponent(filename).path)[FileAttributeKey.modificationDate] as? Date
                        if let date, date.compare(newestDate) == .orderedDescending {
                            newestDate = date
                        }
                    } catch {
                        completion(.failure(.fileManager(step: .modificationDate, fileName: filename, underlyingError: error)))
                        return
                    }
                }
                completion(.success(newestDate))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    public func contentsOfItemAt(url: URL, completion: @escaping (Result<[String], CopyDataBasesErrorEntity>) -> Void) {
        do {
            let pathContent = try fileManager.contentsOfDirectory(atPath: url.path)
            completion(.success(pathContent))
        } catch {
            completion(.failure(.fileManager(step: .directoryContents, fileName: nil, underlyingError: error)))
        }
    }
    
    public func removeContentsOfItemAt(url: URL, completion: @escaping (Result<Void, CopyDataBasesErrorEntity>) -> Void) {
        contentsOfItemAt(url: url) { (result) in
            switch result {
            case .success(let pathContent):
                for filename in pathContent where filename.contains("megaclient") || filename.contains("karere") {
                    do {
                        try fileManager.removeItem(at: url.appendingPathComponent(filename))
                    } catch {
                        completion(.failure(.fileManager(step: .removeContents, fileName: filename, underlyingError: error)))
                        return
                    }
                }
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func copyContentsOfItemAt(url: URL, to destination: URL, completion: @escaping (Result<Void, CopyDataBasesErrorEntity>) -> Void) {
        contentsOfItemAt(url: url) { (result) in
            switch result {
            case .success(let pathContent):
                for filename in pathContent where filename.contains("megaclient") || filename.contains("karere") {
                    do {
                        try fileManager.copyItem(at: url.appendingPathComponent(filename), to: destination.appendingPathComponent(filename))
                    } catch {
                        completion(.failure(.fileManager(step: .copyContents, fileName: filename, underlyingError: error)))
                        return
                    }
                }
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Seed database freshness matching

    /// Files whose modification date drives the copy decision. `nodeDatabaseGatedRepo` narrows this to
    /// the node statecache DB only; the default preserves the original `megaclient*`/`karere*` matching
    /// so existing consumers (e.g. the QuickAccess widgets) are unaffected.
    private func matchesFreshnessRelevantFile(_ filename: String) -> Bool {
        gatesFreshnessOnNodeDatabaseOnly
            ? isNodeStatecacheDatabase(filename)
            : filename.contains("megaclient") || filename.contains("karere")
    }

    /// The node statecache DB (`megaclient_statecache<version>_<handle>.db`) is the only file whose
    /// modification date reflects the freshness of the file tree.
    private func isNodeStatecacheDatabase(_ filename: String) -> Bool {
        filename.contains("megaclient_statecache")
            && !filename.contains("_prefs")
            && !filename.contains("_status")
            && !filename.contains("_transfers")
    }
}
