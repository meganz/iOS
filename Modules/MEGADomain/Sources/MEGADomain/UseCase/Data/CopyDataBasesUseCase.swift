import Foundation

// MARK: - Use case protocol -
public protocol CopyDataBasesUseCaseProtocol {
    func copyFromMainApp(completion: @escaping (Result<Void, GetFavouriteNodesErrorEntity>) -> Void)
}

// MARK: - Use case implementation -
public struct CopyDataBasesUseCase<T: CopyDataBasesRepositoryProtocol>: CopyDataBasesUseCaseProtocol {
    
    private let repo: T

    public init(repo: T) {
        self.repo = repo
    }
    
    public func copyFromMainApp(completion: @escaping (Result<Void, GetFavouriteNodesErrorEntity>) -> Void) {
        
        repo.applicationSupportDirectoryURL { (result) in
            switch result {
            case .success(let applicationURL):
                repo.groupSupportDirectoryURL { (result) in
                    switch result {
                    case .success(let groupUrl):
                        repo.newestModificationDateOfItemAt(url: applicationURL) { (result) in
                            switch result {
                            case .success(let applicationNewestDate):
                                repo.newestModificationDateOfItemAt(url: groupUrl) { (result) in
                                    switch result {
                                    case .success(let groupNewestDate):
                                        if applicationNewestDate.compare(groupNewestDate) == .orderedAscending {
                                            repo.removeContentsOfItemAt(url: applicationURL) { (result) in
                                                switch result {
                                                case .success:
                                                    repo.copyContentsOfItemAt(url: groupUrl, to: applicationURL) { (result) in
                                                        switch result {
                                                        case .success:
                                                            completion(.success(()))
                                                        case .failure(let error):
                                                            completion(.failure(error))
                                                        }
                                                    }
                                                case .failure(let error):
                                                    completion(.failure(error))
                                                }
                                            }
                                        }
                                    case .failure(let error):
                                        completion(.failure(error))
                                    }
                                }
                            case .failure(let error):
                                completion(.failure(error))
                            }
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
