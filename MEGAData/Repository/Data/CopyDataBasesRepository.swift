import MEGADomain

struct CopyDataBasesRepository: CopyDataBasesRepositoryProtocol {
 
    let fileManager: FileManager
    
    init(fileManager: FileManager) {
        self.fileManager = fileManager
    }
    
    func applicationSupportDirectoryURL(completion: @escaping (Result<URL, GetFavouriteNodesErrorEntity>) -> Void) {
        do {
            let applicationSupportDirectoryURL = try fileManager.url(for: FileManager.SearchPathDirectory.applicationSupportDirectory, in: FileManager.SearchPathDomainMask.userDomainMask, appropriateFor: nil, create: true)
            completion(.success(applicationSupportDirectoryURL))
        } catch {
            MEGALogError("Failed copy Databases From Main App with error: \(error)");
            completion(.failure(.fileManager))
        }
    }
    
    func groupSupportDirectoryURL(completion: @escaping (Result<URL, GetFavouriteNodesErrorEntity>) -> Void) {
        guard let groupSupportURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: MEGAGroupIdentifier)?.appendingPathComponent(MEGAExtensionGroupSupportFolder) else {
            MEGALogError("No groupSupportURL")
            completion(.failure(.fileManager))
            return
        }
        
        completion(.success(groupSupportURL))
    }
    
    func newestModificationDateOfItemAt(url: URL, completion: @escaping (Result<Date, GetFavouriteNodesErrorEntity>) -> Void) {
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
                            MEGALogError("Error getting newest modification date of contents at url: \(url)")
                            completion(.failure(.fileManager))
                        }
                    }
                }
                completion(.success(newestDate))
            case .failure(_):
                completion(.failure(.fileManager))
            }
        }
    }
    
    func contentsOfItemAt(url: URL, completion: @escaping (Result<[String], GetFavouriteNodesErrorEntity>) -> Void) {

        do {
            let pathContent = try fileManager.contentsOfDirectory(atPath: url.path)
            completion(.success(pathContent))
        } catch {
            MEGALogError("Error getting contents at url: \(url)")
            completion(.failure(.fileManager))
        }
    }
    
    func removeContentsOfItemAt(url: URL, completion: @escaping (Result<Void, GetFavouriteNodesErrorEntity>) -> Void) {
        contentsOfItemAt(url: url) { (result) in
            switch result {
            case .success(let pathContent):
                for filename in pathContent {
                    if filename.contains("megaclient") || filename.contains("karere") {
                        fileManager.mnz_removeItem(atPath: url.appendingPathComponent(filename).path)
                    }
                }
                completion(.success(()))
            case .failure(_):
                completion(.failure(.fileManager))
            }
        }
    }
    
    func copyContentsOfItemAt(url: URL, to destination: URL, completion: @escaping (Result<Void, GetFavouriteNodesErrorEntity>) -> Void) {
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
                } catch  {
                    MEGALogError("Failed copy items from group to application support with error: \(error)");
                    completion(.failure(.fileManager))
                }
            case .failure(_):
                completion(.failure(.fileManager))
            }
        }
    }
}
