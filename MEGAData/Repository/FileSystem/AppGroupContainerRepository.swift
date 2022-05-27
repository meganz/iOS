import Foundation

extension AppGroupContainerRepository {
    static let `default` = AppGroupContainerRepository(fileManager: .default)
}

struct AppGroupContainerRepository: AppGroupContainerRepositoryProtocol {
    private let fileManager: FileManager
    private let container: AppGroupContainer
    
    init(fileManager: FileManager) {
        self.fileManager = fileManager
        container = AppGroupContainer(fileManager: fileManager)
    }
    
    func cleanContainer() {
        for directory in AppGroupContainer.Directory.allCases {
            let url = container.url(for: directory)
            fileManager.mnz_removeItem(atPath: url.path)
        }
    }
}
