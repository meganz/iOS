import Foundation

public protocol FileExistUseCaseProtocol {
    func fileExists(at url: URL) -> Bool
}

public struct FileExistUseCase: FileExistUseCaseProtocol {
    private let fileSystemRepository: FileSystemRepositoryProtocol
    
    public init(fileSystemRepository: FileSystemRepositoryProtocol) {
        self.fileSystemRepository = fileSystemRepository
    }
    
    public func fileExists(at url: URL) -> Bool {
        fileSystemRepository.fileExists(at: url)
    }
}
