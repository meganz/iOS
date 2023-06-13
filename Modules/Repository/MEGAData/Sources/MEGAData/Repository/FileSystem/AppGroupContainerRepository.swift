import Foundation
import MEGADomain

public struct AppGroupContainerRepository: AppGroupContainerRepositoryProtocol {
    public static var newRepo: AppGroupContainerRepository {
        AppGroupContainerRepository(fileManager: .default,
                                    fileSystemRepository: FileSystemRepository.newRepo)
    }
    
    private let container: AppGroupContainer
    private let fileSystemRepository: any FileSystemRepositoryProtocol
    
    public init(fileManager: FileManager,
                fileSystemRepository: any FileSystemRepositoryProtocol
    ) {
        self.fileSystemRepository = fileSystemRepository
        container = AppGroupContainer(fileManager: fileManager)
    }
    
    public func cleanContainer() {
        for directory in AppGroupContainer.Directory.allCases {
            let url = container.url(for: directory)
            fileSystemRepository.removeFile(at: url)
        }
    }
}
