import Foundation

// MARK: - Use case protocol -
protocol CopyDataBasesUseCaseProtocol {
    func copyFromMainApp(completion: @escaping (Result<Void, QuickAccessWidgetErrorEntity>) -> Void)
}

// MARK: - Use case implementation -
struct CopyDataBasesUseCase: CopyDataBasesUseCaseProtocol {
    
    private let repo: CopyDataBasesRepositoryProtocol

    init(repo: CopyDataBasesRepositoryProtocol) {
        self.repo = repo
    }
    
    func copyFromMainApp(completion: @escaping (Result<Void, QuickAccessWidgetErrorEntity>) -> Void) {
        MEGALogDebug("Copy databases from main app")
        
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
                                                case .success(_):
                                                    repo.copyContentsOfItemAt(url: groupUrl, to: applicationURL) { (result) in
                                                        switch result {
                                                        case .success(_):
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
