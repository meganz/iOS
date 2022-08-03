import Foundation
import MEGAFoundation

// MARK: - Use case protocol -
protocol NameCollisionUseCaseProtocol {
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
struct NameCollisionUseCase<T: NodeRepositoryProtocol, U: FileSystemRepositoryProtocol>: NameCollisionUseCaseProtocol {
    private let nodeRepository: T
    private let fileSystemRepository: U
    
    private let formatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter
    }()
    
    init(nodeRepository: T, fileSystemRepository: U) {
        self.nodeRepository = nodeRepository
        self.fileSystemRepository = fileSystemRepository
    }
    
    func resolveNameCollisions(for collisions: [NameCollisionEntity]) -> [NameCollisionEntity] {
        collisions.forEach { collision in
            collision.collisionNodeHandle = nodeRepository.childNodeNamed(name: collision.name, in: collision.parentHandle)?.handle
        }
        return collisions
    }
    
    func copyNodesFromResolvedCollisions(_ collisions: [NameCollisionEntity], isFolderLink: Bool) async throws -> [HandleEntity] {
        try await withThrowingTaskGroup(of: HandleEntity.self, returning: [HandleEntity].self) { group in
            for collision in collisions {
                group.addTask {
                    return try await nodeRepository.copyNode(handle: collision.nodeHandle ?? .invalid, in: collision.parentHandle, newName: collision.renamed, isFolderLink: isFolderLink)
                }
            }
            
            return try await group.reduce(into: [HandleEntity](), { result, handle in
                result.append(handle)
            })

        }
    }
    
    func moveNodesFromResolvedCollisions(_ collisions: [NameCollisionEntity]) async throws -> [HandleEntity] {
        try await withThrowingTaskGroup(of: HandleEntity.self, returning: [HandleEntity].self) { group in
            for collision in collisions {
                group.addTask {
                    return try await nodeRepository.moveNode(handle: collision.nodeHandle ?? .invalid, in: collision.parentHandle, newName: collision.renamed)
                }
            }
            
            return try await group.reduce(into: [HandleEntity](), { result, handle in
                result.append(handle)
            })

        }
    }
    
    func sizeForNode(handle: HandleEntity) -> String {
        guard let size = nodeRepository.sizeForNode(handle: handle) else {
            return ""
        }

        return formatter.string(fromByteCount: Int64(size))
    }

    func creationDateForNode(handle: HandleEntity) -> String {
        guard let date = nodeRepository.creationDateForNode(handle: handle) else {
            return ""
        }
        
        return DateFormatter.dateMedium().localisedString(from: date)
    }
    
    func sizeForFile(at url: URL) -> String {
        guard let size = fileSystemRepository.fileSize(at: url) else {
            return ""
        }
        
        return formatter.string(fromByteCount: Int64(size))
    }
    
    func creationDateForFile(at url: URL) -> String {
        guard let date = fileSystemRepository.fileCreationDate(at: url) else {
            return ""
        }
        
        return DateFormatter.dateMedium().localisedString(from: date)
    }
    
    func renameNode(named name: NSString, inParent parentHandle: HandleEntity) -> String {
        let counterPattern = #"\(\d+\)"#
        var filename = name.deletingPathExtension
        if let counterRange = filename.range(of: counterPattern, options: .regularExpression) {
            let currentCounter = filename[counterRange]
            guard let counter = Int(currentCounter.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) else {
                return filename + "." + name.pathExtension
            }
            filename.replaceSubrange(counterRange, with: "(\(counter + 1))")
            filename = filename + "." + name.pathExtension
            if (nodeRepository.childNodeNamed(name: filename, in: parentHandle) != nil) {
                return renameNode(named: filename as NSString, inParent: parentHandle)
            } else {
                return filename
            }
        } else {
            filename = filename + " (1)." + name.pathExtension
            if (nodeRepository.childNodeNamed(name: filename, in: parentHandle) != nil) {
                return renameNode(named: filename as NSString, inParent: parentHandle)
            } else {
                return filename
            }
        }
    }
    
    func node(for handle: HandleEntity) -> NodeEntity? {
        nodeRepository.nodeForHandle(handle)
    }
}
