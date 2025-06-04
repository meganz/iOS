import Foundation
import MEGADomain
import MEGARepo

public struct AppGroupContainerRepository: AppGroupContainerRepositoryProtocol {
    public static var newRepo: AppGroupContainerRepository {
        AppGroupContainerRepository(fileManager: .default,
                                    fileSystemRepository: FileSystemRepository.sharedRepo)
    }
    
    private let container: AppGroupContainer
    private let fileSystemRepository: any FileSystemRepositoryProtocol
    
    public init(fileManager: FileManager,
                fileSystemRepository: any FileSystemRepositoryProtocol
    ) {
        self.fileSystemRepository = fileSystemRepository
        container = AppGroupContainer(fileManager: fileManager)
    }
    
    public func cleanContainer() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTasksUnlessCancelled(for: AppGroupContainer.Directory.allCases) { directory in
                let url = container.url(for: directory)
                try? await fileSystemRepository.removeItem(at: url)
            }
        }
    }
}
