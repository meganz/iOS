import FileProvider
import Foundation
import MEGADomain

public protocol FileProviderEnumeratorUseCaseProtocol: Sendable {
    ///  Return a list of nodes that are directly under the provided NSFileProviderItemIdentifier. The returned list of nodes excludes any nodes marked or inherit sensitivity.
    /// - Parameter identifier: NSFileProviderItemIdentifier containing the base64Handle identifying a Node
    /// - Returns: If the given identifier is a folder node, return all nodes under that folder. Else, return the node itself only
    func fetchItems(for identifier: NSFileProviderItemIdentifier) async throws -> [NodeEntity]
}

public final class FileProviderEnumeratorUseCase<S: FilesSearchRepositoryProtocol, T: NodeRepositoryProtocol, U: MEGAHandleRepositoryProtocol>: FileProviderEnumeratorUseCaseProtocol {
    
    private let filesSearchRepo: S
    private let nodeRepo: T
    private let megaHandleRepo: U
    
    public init(filesSearchRepo: S, nodeRepo: T, megaHandleRepo: U) {
        self.filesSearchRepo = filesSearchRepo
        self.nodeRepo = nodeRepo
        self.megaHandleRepo = megaHandleRepo
    }
    
    public func fetchItems(for identifier: NSFileProviderItemIdentifier) async throws -> [NodeEntity] {
        let searchTargetNode: NodeEntity = if identifier == NSFileProviderItemIdentifier.rootContainer,
            let rootNode = nodeRepo.rootNode() {
            rootNode
        } else if let handle = megaHandleRepo.handle(forBase64Handle: identifier.rawValue),
            let node = nodeRepo.nodeForHandle(handle) {
            node
        } else {
            throw NSFileProviderError(.noSuchItem)
        }
        
        return if searchTargetNode.isFolder {
            try await filesSearchRepo.search(filter: .nonRecursive(
                searchText: nil,
                searchTargetNode: searchTargetNode,
                supportCancel: false,
                sortOrderType: .defaultAsc,
                formatType: .unknown,
                sensitiveFilterOption: .nonSensitiveOnly))
        } else {
            [searchTargetNode]
        }
    }
}
