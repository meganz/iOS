import FileProvider
import MEGADomain
import MEGAPickerFileProviderDomain
import os

/// Returns each identifier's items in the order given, one per call, then keeps returning the last one: the item
/// before a change, and then after it. An identifier without items throws `noSuchItem`.
struct MockSequencedFileProviderItemUseCase: FileProviderItemUseCaseProtocol {
    private let itemsByIdentifier: OSAllocatedUnfairLock<[NSFileProviderItemIdentifier: [FileProviderItemEntity]]>

    init(_ items: [FileProviderItemEntity]) {
        itemsByIdentifier = OSAllocatedUnfairLock(initialState: Dictionary(grouping: items, by: \.identifier))
    }

    func item(for identifier: NSFileProviderItemIdentifier) throws -> FileProviderItemEntity {
        let item = itemsByIdentifier.withLock { remaining -> FileProviderItemEntity? in
            guard let items = remaining[identifier] else { return nil }
            if items.count > 1 {
                remaining[identifier] = Array(items.dropFirst())
            }
            return items.first
        }
        guard let item else {
            throw NSFileProviderError(.noSuchItem)
        }
        return item
    }

    func children(of containerIdentifier: NSFileProviderItemIdentifier, page: SearchPageEntity) async throws -> [FileProviderItemEntity] {
        []
    }

    func presentableItem(for identifier: NSFileProviderItemIdentifier) throws -> FileProviderItemEntity? {
        try? item(for: identifier)
    }
}
