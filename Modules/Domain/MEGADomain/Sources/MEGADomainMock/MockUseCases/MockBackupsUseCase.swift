import Foundation
import MEGADomain

public struct MockBackupsUseCase: BackupsUseCaseProtocol {
    private let isBackupsNode: Bool
    private var containsABackupNode: Bool
    private var isBackupsRootNode: Bool
    private var isInBackups: Bool
    
    public init(
        isBackupsNode: Bool = false,
        isBackupsRootNode: Bool = false,
        containsABackupNode: Bool = false ,
        isInBackups: Bool = false
    ) {
        self.isBackupsNode = isBackupsNode
        self.isBackupsRootNode = isBackupsRootNode
        self.containsABackupNode = containsABackupNode
        self.isInBackups = isInBackups
    }
    
    public func hasBackupNode(in nodes: [NodeEntity]) -> Bool {
        containsABackupNode
    }
    
    public func isBackupNode(_ node: NodeEntity) -> Bool {
        isBackupsNode
    }
    
    public func isBackupsRootNode(_ node: NodeEntity) -> Bool {
        isBackupsRootNode
    }
    
    public func isBackupNodeHandle(_ nodeHandle: HandleEntity) -> Bool {
        isBackupsNode
    }
    
    public func parentsForBackupHandle(_ handle: HandleEntity) async -> [NodeEntity]? {
        []
    }
}
