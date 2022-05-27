import Foundation

protocol CheckLocalPathUseCaseProtocol {
    func containsOriginalCacheDirectory(path: String) -> Bool
}

struct CheckLocalPathUseCase<T: FileCacheRepositoryProtocol>: CheckLocalPathUseCaseProtocol {
    private let repo: T
    
    init(repo: T) {
        self.repo = repo
    }
    
    func containsOriginalCacheDirectory(path: String) -> Bool {
        path.contains(repo.cachedOriginalImageDirectoryURL.path)
    }
}
