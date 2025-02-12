import Foundation
import MEGADomain

public struct MockBackupsRepository: BackupsRepositoryProtocol {
    public static let newRepo = MockBackupsRepository()
    private let currentBackupNode: NodeEntity
    private let isBackupNode: Bool
    
    public init(
        currentBackupNode: NodeEntity = NodeEntity(name: "backup"),
        isBackupNode: Bool = false
    ) {
        self.currentBackupNode = currentBackupNode
        self.isBackupNode = isBackupNode
    }
    
    public func isBackupNode(_ node: NodeEntity) -> Bool {
        isBackupNode
    }
    
    public func isBackupsRootNode(_ node: NodeEntity) -> Bool {
        currentBackupNode.handle == node.handle
    }
}
