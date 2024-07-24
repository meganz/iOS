import Foundation
import MEGAFoundation

// MARK: - Use case protocol -
public protocol NameCollisionUseCaseProtocol: Sendable {
    func resolveNameCollisions(for collisions: [NameCollisionEntity]) -> [NameCollisionEntity]
    func copyNodesFromResolvedCollisions(_ collisions: [NameCollisionEntity], isFolderLink: Bool) async throws -> [HandleEntity]
    func moveNodesFromResolvedCollisions(_ collisions: [NameCollisionEntity]) async throws -> [HandleEntity]
    func sizeForNode(handle: HandleEntity) -> String
    func creationDateForNode(handle: HandleEntity) -> String
    func sizeForFile(at url: URL) -> String
    func creationDateForFile(at url: URL) -> String
    func renameNode(named name: NSString, inParent parentHandle: HandleEntity) -> String
    func node(for handle: HandleEntity) -> NodeEntity?
}

// MARK: - Use case implementation -
public struct NameCollisionUseCase<T: NodeRepositoryProtocol, U: NodeActionsRepositoryProtocol, V: NodeDataRepositoryProtocol, W: FileSystemRepositoryProtocol>: NameCollisionUseCaseProtocol {
    private let nodeRepository: T
    private let nodeActionsRepository: U
    private let nodeDataRepository: V
    private let fileSystemRepository: W
    
    private let formatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter
    }()
    
    public init(nodeRepository: T, nodeActionsRepository: U, nodeDataRepository: V, fileSystemRepository: W) {
        self.nodeRepository = nodeRepository
        self.nodeActionsRepository = nodeActionsRepository
        self.nodeDataRepository = nodeDataRepository
        self.fileSystemRepository = fileSystemRepository
    }
    
    public func resolveNameCollisions(for collisions: [NameCollisionEntity]) -> [NameCollisionEntity] {
        var resolvedCollisions = [NameCollisionEntity]()
        for var collision in collisions {
            collision.collisionNodeHandle = nodeRepository.childNodeNamed(name: collision.name, in: collision.parentHandle)?.handle
            resolvedCollisions.append(collision)
        }
        return resolvedCollisions.sorted { !$0.isFile && $1.isFile }
    }
    
    public func copyNodesFromResolvedCollisions(_ collisions: [NameCollisionEntity], isFolderLink: Bool) async throws -> [HandleEntity] {
        try await withThrowingTaskGroup(of: HandleEntity.self, returning: [HandleEntity].self) { group in
            for collision in collisions {
                group.addTask {
                    try await removeOriginalDuplicatedItemIfNeeded(for: collision)
                    return try await nodeActionsRepository.copyNode(handle: collision.nodeHandle ?? .invalid, in: collision.parentHandle, newName: collision.renamed, isFolderLink: isFolderLink)
                }
            }
            
            return try await group.reduce(into: [HandleEntity](), { result, handle in
                result.append(handle)
            })

        }
    }
    
    public func moveNodesFromResolvedCollisions(_ collisions: [NameCollisionEntity]) async throws -> [HandleEntity] {
        try await withThrowingTaskGroup(of: HandleEntity.self, returning: [HandleEntity].self) { group in
            for collision in collisions {
                group.addTask {
                    try await removeOriginalDuplicatedItemIfNeeded(for: collision)
                    return try await nodeActionsRepository.moveNode(handle: collision.nodeHandle ?? .invalid, in: collision.parentHandle, newName: collision.renamed)
                }
            }
            
            return try await group.reduce(into: [HandleEntity](), { result, handle in
                result.append(handle)
            })

        }
    }
    
    public func sizeForNode(handle: HandleEntity) -> String {
        guard let size = nodeDataRepository.sizeForNode(handle: handle) else {
            return ""
        }

        return formatter.string(fromByteCount: Int64(size))
    }

    public func creationDateForNode(handle: HandleEntity) -> String {
        guard let date = nodeDataRepository.creationDateForNode(handle: handle) else {
            return ""
        }
        
        return DateFormatter.dateMedium().localisedString(from: date)
    }
    
    public func sizeForFile(at url: URL) -> String {
        guard let size = fileSystemRepository.fileSize(at: url) else {
            return ""
        }
        
        return formatter.string(fromByteCount: Int64(size))
    }
    
    public func creationDateForFile(at url: URL) -> String {
        guard let date = fileSystemRepository.fileCreationDate(at: url) else {
            return ""
        }
        
        return DateFormatter.dateMedium().localisedString(from: date)
    }
    
    public func renameNode(named name: NSString, inParent parentHandle: HandleEntity) -> String {
        let counterPattern = #"\(\d+\)"#
        let fileName = name.deletingPathExtension
        let pathExtension = name.pathExtension
        
        var newFileName = fileName
        var counter = 1
        
        while counter < Int.max {
            if let counterRange = newFileName.range(of: counterPattern, options: .regularExpression) {
                newFileName.replaceSubrange(counterRange, with: "(\(counter))")
            } else {
                newFileName = fileName + " (\(counter))"
            }
                        
            let searchFileName = newFileName + "." + pathExtension
            
            if nodeRepository.childNodeNamed(name: searchFileName, in: parentHandle) == nil {
                return searchFileName
            }
            
            counter += 1
        }
        
        return name as String
    }
    
    public func node(for handle: HandleEntity) -> NodeEntity? {
        nodeRepository.nodeForHandle(handle)
    }
    
    // MARK: - Private
    private func removeOriginalDuplicatedItemIfNeeded(for collision: NameCollisionEntity) async throws {
        if collision.collisionAction == .replace || collision.collisionAction == .update, 
            let collisionHandle = collision.collisionNodeHandle, 
            let rubbish = nodeRepository.rubbishNode() {
            _ = try await nodeActionsRepository.moveNode(handle: collisionHandle, in: rubbish.handle, newName: nil)
        }
    }
}
