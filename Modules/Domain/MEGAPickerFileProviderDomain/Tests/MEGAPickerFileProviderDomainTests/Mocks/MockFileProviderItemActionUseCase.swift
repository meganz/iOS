import FileProvider
import MEGADomain
import MEGAPickerFileProviderDomain

/// Records each `modifyItem` call and returns `modifiedItem`, or throws `error`. The other calls are not used.
actor MockFileProviderItemActionUseCase: FileProviderItemActionUseCaseProtocol {
    struct Modification: Equatable {
        let identifier: NSFileProviderItemIdentifier
        let name: String?
        let parentIdentifier: NSFileProviderItemIdentifier?
    }

    private let modifiedItem: FileProviderItemEntity
    private let error: (any Error)?
    private(set) var modifications: [Modification] = []

    init(modifiedItem: FileProviderItemEntity = .make("item"), error: (any Error)? = nil) {
        self.modifiedItem = modifiedItem
        self.error = error
    }

    func createFolder(
        named name: String,
        in parentIdentifier: NSFileProviderItemIdentifier,
        reusesExistingFolder: Bool
    ) async throws -> FileProviderItemEntity {
        modifiedItem
    }

    func modifyItem(
        _ identifier: NSFileProviderItemIdentifier,
        name: String?,
        parentIdentifier: NSFileProviderItemIdentifier?
    ) async throws -> FileProviderItemEntity {
        modifications.append(Modification(identifier: identifier, name: name, parentIdentifier: parentIdentifier))
        if let error {
            throw error
        }
        return modifiedItem
    }

    func deleteItem(_ identifier: NSFileProviderItemIdentifier, recursive: Bool) async throws {}
}
