@objc final class CheckLocalPathUseCaseOCWrapper: NSObject {
    private let checkLocalPathUseCase = CheckLocalPathUseCase(repo: FileSystemRepository(fileManager: FileManager.default))
    
    @objc func containsOriginalCacheDirectory(path: String) -> Bool {
        checkLocalPathUseCase.containsOriginalCacheDirectory(path: path)
    }
}
