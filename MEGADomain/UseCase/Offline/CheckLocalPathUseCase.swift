import Foundation

protocol CheckLocalPathUseCaseProtocol {
    func containsOriginalCacheDirectory(path: String) -> Bool
}

struct CheckLocalPathUseCase<T: FileRepositoryProtocol>: CheckLocalPathUseCaseProtocol {

    private let repo: T

    init(repo: T) {
        self.repo = repo
    }
    
    func containsOriginalCacheDirectory(path: String) -> Bool {
        repo.containsOriginalCacheDirectory(path: path)
    }
}
