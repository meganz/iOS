import FileProvider
import Foundation
import MEGADomain

/// Lists the working set: the current children of every folder that has a snapshot, one folder after another.
///
/// The system lists it when the domain is set up, and again after its sync anchor expired, when it drops what it
/// holds; every item it shows has to be in here.
public protocol FileProviderWorkingSetItemsUseCaseProtocol: Sendable {
    /// One page of the working set. The children delivered are recorded in their folder's snapshot.
    /// - Parameter page: The system's initial page, or a `nextPage` this method returned.
    func items(startingAt page: NSFileProviderPage, pageSize: Int) async throws -> FileProviderWorkingSetPageEntity
}

public struct FileProviderWorkingSetItemsUseCase: FileProviderWorkingSetItemsUseCaseProtocol {
    /// Where a page starts: a folder and the offset among its children.
    private struct Position: Codable {
        let container: String
        let offset: Int
    }

    private let itemUseCase: any FileProviderItemUseCaseProtocol
    private let snapshotRepo: any FileProviderSnapshotRepositoryProtocol
    private let enumerationSnapshotUseCase: any FileProviderEnumerationSnapshotUseCaseProtocol

    public init(
        itemUseCase: any FileProviderItemUseCaseProtocol,
        snapshotRepo: any FileProviderSnapshotRepositoryProtocol,
        enumerationSnapshotUseCase: any FileProviderEnumerationSnapshotUseCaseProtocol
    ) {
        self.itemUseCase = itemUseCase
        self.snapshotRepo = snapshotRepo
        self.enumerationSnapshotUseCase = enumerationSnapshotUseCase
    }

    public func items(startingAt page: NSFileProviderPage, pageSize: Int) async throws -> FileProviderWorkingSetPageEntity {
        let containers = try await snapshotRepo.containerIdentifiers().sorted { $0.rawValue < $1.rawValue }
        // The system's initial pages are not positions, and start at the first folder.
        let position = try? JSONDecoder().decode(Position.self, from: page.rawValue)
        // A page in a folder whose snapshot has since been removed starts at the next folder.
        var index = 0
        var offset = 0
        if let position {
            index = containers.firstIndex { $0.rawValue >= position.container } ?? containers.count
            if index < containers.count && containers[index].rawValue == position.container {
                offset = position.offset
            }
        }

        while index < containers.count {
            let container = containers[index]
            let items: [FileProviderItemEntity]
            do {
                items = try await itemUseCase.children(of: container, page: SearchPageEntity(startingOffset: offset, pageSize: pageSize))
            } catch let error as NSFileProviderError where error.code == .noSuchItem
                        && container != .rootContainer && container != .trashContainer {
                // Every folder looks gone while the node tree is not loaded, when this throws `cannotSynchronize`.
                if try itemUseCase.presentableItem(for: container) == nil {
                    // The folder is gone or no longer listed, and the system drops its children with it.
                    try await snapshotRepo.removeSnapshot(of: container)
                }
                index += 1
                offset = 0
                continue
            }

            try await enumerationSnapshotUseCase.didEnumerate(items, in: container)
            let nextPosition: Position? = if items.count == pageSize {
                Position(container: container.rawValue, offset: offset + items.count)
            } else if index + 1 < containers.count {
                Position(container: containers[index + 1].rawValue, offset: 0)
            } else {
                nil
            }
            return FileProviderWorkingSetPageEntity(
                items: items,
                nextPage: try nextPosition.map { NSFileProviderPage(try JSONEncoder().encode($0)) }
            )
        }
        return FileProviderWorkingSetPageEntity(items: [], nextPage: nil)
    }
}
