@objc final class CheckLocalPathUseCaseOCWrapper: NSObject {
    private let checkLocalPathUseCase = CheckLocalPathUseCase(repo: FileCacheRepository.default)
    
    @objc func containsOriginalCacheDirectory(path: String) -> Bool {
        checkLocalPathUseCase.containsOriginalCacheDirectory(path: path)
    }
}
