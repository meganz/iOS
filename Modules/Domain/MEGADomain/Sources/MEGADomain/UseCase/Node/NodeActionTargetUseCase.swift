import Foundation
import MEGAPreference

public protocol NodeActionTargetUseCaseProtocol {
    func lastTargetNodeTreeArray(for action: BrowserActionEntity) async -> [NodeEntity]?
    func record(target: NodeEntity, for action: BrowserActionEntity)
    func target(for action: BrowserActionEntity) -> HandleEntity?
}

public struct NodeActionTargetUseCase<T: NodeRepositoryProtocol, U: PreferenceUseCaseProtocol>: NodeActionTargetUseCaseProtocol, Sendable {
    private let nodeRepo: T
    private let secondsInOneHour: TimeInterval = 3600
    
    @PreferenceWrapper(key: PreferenceKeyEntity.lastMoveActionTargetPath, defaultValue: nil)
    private var lastMoveActionTargetPath: HandleEntity?
    @PreferenceWrapper(key: PreferenceKeyEntity.lastMoveActionTargetDate, defaultValue: Date(timeIntervalSince1970: 0))
    private var lastMoveActionTargetDate: Date
    @PreferenceWrapper(key: PreferenceKeyEntity.lastCopyActionTargetPath, defaultValue: nil)
    private var lastCopyActionTargetPath: HandleEntity?
    @PreferenceWrapper(key: PreferenceKeyEntity.lastCopyActionTargetDate, defaultValue: Date(timeIntervalSince1970: 0))
    private var lastCopyActionTargetDate: Date
    
    public init(nodeRepo: T, preferenceUseCase: U) {
        self.nodeRepo = nodeRepo
        $lastMoveActionTargetPath.useCase = preferenceUseCase
        $lastMoveActionTargetDate.useCase = preferenceUseCase
        $lastCopyActionTargetPath.useCase = preferenceUseCase
        $lastCopyActionTargetDate.useCase = preferenceUseCase
    }
    
    public func lastTargetNodeTreeArray(for action: BrowserActionEntity) async -> [NodeEntity]? {
        var lastActionTargetPath: HandleEntity?
        var lastActionTargetDate: Date?
        if case .copy = action {
            lastActionTargetPath = lastCopyActionTargetPath
            lastActionTargetDate = lastCopyActionTargetDate
        } else if case .move = action {
            lastActionTargetPath = lastMoveActionTargetPath
            lastActionTargetDate = lastMoveActionTargetDate
        }
        
        if let lastActionTargetPath, let lastActionTargetDate {
            let timeInterval = Date().timeIntervalSince(lastActionTargetDate)
            if timeInterval <= secondsInOneHour {
                guard let targetNode = nodeRepo.nodeForHandle(lastActionTargetPath),
                        !nodeRepo.isInRubbishBin(node: targetNode) else {
                    return nil
                }
                return await nodeRepo.parents(of: targetNode)
            }
        }
        
        return nil
    }
    
    public func record(target: NodeEntity, for action: BrowserActionEntity) {
        if case .copy = action {
            lastCopyActionTargetDate = Date()
            lastCopyActionTargetPath = target.handle
        } else if case .move = action {
            lastMoveActionTargetDate = Date()
            lastMoveActionTargetPath = target.handle
        }
    }
    
    public func target(for action: BrowserActionEntity) -> HandleEntity? {
        if case .copy = action {
            return lastCopyActionTargetPath
        } else if case .move = action {
            return lastMoveActionTargetPath
        }
        return nil
    }
}
