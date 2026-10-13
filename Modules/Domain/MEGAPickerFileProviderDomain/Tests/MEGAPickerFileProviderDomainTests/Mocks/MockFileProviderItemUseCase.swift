import FileProvider
import MEGADomain
import MEGAPickerFileProviderDomain

struct MockFileProviderItemUseCase: FileProviderItemUseCaseProtocol {
    /// Each container's children, served a page at a time; a container missing here throws `noSuchItem`.
    var childrenByContainer: [NSFileProviderItemIdentifier: [FileProviderItemEntity]] = [:]
    /// The items `presentableItem(for:)` returns; any other identifier is not presentable.
    var presentableItems: [FileProviderItemEntity] = []
    var presentableItemError: NSFileProviderError?

    func item(for identifier: NSFileProviderItemIdentifier) throws -> FileProviderItemEntity {
        guard let item = presentableItems.first(where: { $0.identifier == identifier }) else {
            throw NSFileProviderError(.noSuchItem)
        }
        return item
    }

    func children(of containerIdentifier: NSFileProviderItemIdentifier, page: SearchPageEntity) async throws -> [FileProviderItemEntity] {
        guard let children = childrenByContainer[containerIdentifier] else {
            throw NSFileProviderError(.noSuchItem)
        }
        let start = min(page.startingOffset, children.count)
        return Array(children[start..<min(start + page.pageSize, children.count)])
    }

    func presentableItem(for identifier: NSFileProviderItemIdentifier) throws -> FileProviderItemEntity? {
        if let presentableItemError {
            throw presentableItemError
        }
        return presentableItems.first { $0.identifier == identifier }
    }
}
