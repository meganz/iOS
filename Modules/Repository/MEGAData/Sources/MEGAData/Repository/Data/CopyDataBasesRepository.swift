import Foundation
import MEGADomain

public struct CopyDataBasesRepository: CopyDataBasesRepositoryProtocol {
    public static var newRepo: CopyDataBasesRepository {
        CopyDataBasesRepository(fileManager: FileManager.default)
       }
 
    let fileManager: FileManager
    
    enum Constants {
        static let groupIdentifier = "group.mega.ios"
        static let extensionGroupSupportFolder = "GroupSupport"
    }
    
    public init(fileManager: FileManager) {
        self.fileManager = fileManager
    }
    
    public func applicationSupportDirectoryURL(completion: @escaping (Result<URL, GetFavouriteNodesErrorEntity>) -> Void) {
        do {
            let applicationSupportDirectoryURL = try fileManager.url(for: FileManager.SearchPathDirectory.applicationSupportDirectory, in: FileManager.SearchPathDomainMask.userDomainMask, appropriateFor: nil, create: true)
            completion(.success(applicationSupportDirectoryURL))
        } catch {
            completion(.failure(.fileManager))
        }
    }
    
    public func groupSupportDirectoryURL(completion: @escaping (Result<URL, GetFavouriteNodesErrorEntity>) -> Void) {
        guard let groupSupportURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: Constants.groupIdentifier)?.appendingPathComponent(
            Constants.extensionGroupSupportFolder) else {
            completion(.failure(.fileManager))
            return
        }
        
        completion(.success(groupSupportURL))
    }
    
    public func newestModificationDateOfItemAt(url: URL, completion: @escaping (Result<Date, GetFavouriteNodesErrorEntity>) -> Void) {
        var newestDate = Date(timeIntervalSince1970: 0)

        contentsOfItemAt(url: url) { (result) in
            switch result {
            case .success(let pathContent):
                for filename in pathContent {
                    if filename.contains("megaclient") || filename.contains("karere") {
                        do {
                            let date = try fileManager.attributesOfItem(atPath: url.appendingPathComponent(filename).path)[FileAttributeKey.modificationDate] as? Date
                            if date?.compare(newestDate) == .orderedDescending {
                                newestDate = date!
                            }
                        } catch {
                            completion(.failure(.fileManager))
                        }
                    }
                }
                completion(.success(newestDate))
            case .failure:
                completion(.failure(.fileManager))
            }
        }
    }
    
    public func contentsOfItemAt(url: URL, completion: @escaping (Result<[String], GetFavouriteNodesErrorEntity>) -> Void) {

        do {
            let pathContent = try fileManager.contentsOfDirectory(atPath: url.path)
            completion(.success(pathContent))
        } catch {
            completion(.failure(.fileManager))
        }
    }
    
    public func removeContentsOfItemAt(url: URL, completion: @escaping (Result<Void, GetFavouriteNodesErrorEntity>) -> Void) {
        contentsOfItemAt(url: url) { (result) in
            switch result {
            case .success(let pathContent):
                for filename in pathContent {
                    if filename.contains("megaclient") || filename.contains("karere") {
                        do {
                            try fileManager.removeItem(at: url.appendingPathComponent(filename))
                        } catch {
                            completion(.failure(.fileManager))
                        }
                    }
                }
                completion(.success(()))
            case .failure:
                completion(.failure(.fileManager))
            }
        }
    }
    
    public func copyContentsOfItemAt(url: URL, to destination: URL, completion: @escaping (Result<Void, GetFavouriteNodesErrorEntity>) -> Void) {
        contentsOfItemAt(url: url) { (result) in
            switch result {
            case .success(let pathContent):
                do {
                    for filename in pathContent {
                        if filename.contains("megaclient") || filename.contains("karere") {
                            try fileManager.copyItem(at: url.appendingPathComponent(filename), to: destination.appendingPathComponent(filename))
                        }
                    }
                    completion(.success(()))
                } catch {
                    completion(.failure(.fileManager))
                }
            case .failure:
                completion(.failure(.fileManager))
            }
        }
    }
}
