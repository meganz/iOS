import MEGADomain

public struct MockNodeActionsRepository: NodeActionsRepositoryProtocol {
    public static let newRepo: MockNodeActionsRepository = MockNodeActionsRepository()
    
    private let copiedNodeIfExists: Bool
    private let copiedNodeHandle: UInt64?
    private let movedNodeHandle: UInt64?
    
    public init(copiedNodeIfExists: Bool = false, copiedNodeHandle: UInt64? = nil, movedNodeHandle: UInt64? = nil) {
        self.copiedNodeIfExists = copiedNodeIfExists
        self.copiedNodeHandle = copiedNodeHandle
        self.movedNodeHandle = movedNodeHandle
    }
    
    public func copyNodeIfExistsWithSameFingerprint(at path: String, parentHandle: HandleEntity, newName: String?) -> Bool {
        copiedNodeIfExists
    }
    
    public func copyNode(handle: MEGADomain.HandleEntity, in parentHandle: HandleEntity, newName: String?, isFolderLink: Bool) async throws -> HandleEntity {
        guard let copiedNodeHandle = copiedNodeHandle else {
            throw CopyOrMoveErrorEntity.generic
        }
        return copiedNodeHandle
    }
    
    public func moveNode(handle: MEGADomain.HandleEntity, in parentHandle: HandleEntity, newName: String?) async throws -> HandleEntity {
        guard let movedNodeHandle = movedNodeHandle else {
            throw CopyOrMoveErrorEntity.generic
        }
        return movedNodeHandle
    }
}
