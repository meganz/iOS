@preconcurrency import FileProvider
import MEGAAppSDKRepo
import MEGADomain
import MEGAPickerFileProviderDomain
import MEGARepo

/// Entry point of the File Provider extension on `NSFileProviderReplicatedExtension`.
///
/// Only used when the `MEGA_FILE_PROVIDER_PRINCIPAL_CLASS` build setting points at it; `FileProviderExtension`
/// stays the shipping implementation until the switch. For now it only serves browsing.
final class ReplicatedFileProviderExtension: NSObject, NSFileProviderReplicatedExtension {
    private let domain: NSFileProviderDomain
    private let credentialUseCase = CredentialUseCase(repo: CredentialRepository.newRepo)

    /// Built on every use rather than stored: its repositories reach `MEGASdk.shared`, which must not exist before
    /// `init` has copied the databases, and a `lazy var` is not safe to initialise from the concurrent calls the
    /// system makes.
    private var itemUseCase: some FileProviderItemUseCaseProtocol {
        FileProviderItemUseCase(
            filesSearchRepo: FilesSearchRepository.newRepo,
            nodeRepo: NodeRepository.newRepo,
            megaHandleRepo: MEGAHandleRepository.newRepo,
            nodeAttributeRepo: NodeAttributeRepository.newRepo
        )
    }

    // Nothing here may create `MEGASdk.shared` before `copyDatabasesFromMainApp()`: an SDK that opens its
    // databases first stamps them with a fresh modification date, and the copy then wrongly skips them (IOS-7447).
    init(domain: NSFileProviderDomain) {
        self.domain = domain
        super.init()
        AppEnvironmentConfigurator.configAppEnvironment()
#if DEBUG
        MEGASdk.setLogLevel(.max)
#endif
        MEGASdk.setLogToConsole(true)
        MEGALogDebug("[Picker] Replicated extension started for domain \(domain.identifier.rawValue)")
        copyDatabasesFromMainApp()
    }

    func invalidate() {
        MEGALogDebug("[Picker] Replicated extension invalidated for domain \(domain.identifier.rawValue)")
    }

    // MARK: - Items

    func item(
        for identifier: NSFileProviderItemIdentifier,
        request: NSFileProviderRequest,
        completionHandler: @escaping (NSFileProviderItem?, (any Error)?) -> Void
    ) -> Progress {
        let itemUseCase = itemUseCase
        let completion = UncheckedSendableCompletion(completionHandler)
        Task {
            do {
                try await FileProviderSession.shared.ensureReady()
                completion.handler(ReplicatedFileProviderItem(entity: try itemUseCase.item(for: identifier)), nil)
            } catch {
                MEGALogError("[Picker] Can't provide the item \(identifier.rawValue): \(error)")
                completion.handler(nil, FileProviderExtension.fileProviderError(for: error))
            }
        }
        return Progress()
    }

    func fetchContents(
        for itemIdentifier: NSFileProviderItemIdentifier,
        version requestedVersion: NSFileProviderItemVersion?,
        request: NSFileProviderRequest,
        completionHandler: @escaping (URL?, NSFileProviderItem?, (any Error)?) -> Void
    ) -> Progress {
        MEGALogDebug("[Picker] fetchContents is not supported yet: \(itemIdentifier.rawValue)")
        completionHandler(nil, nil, CocoaError(.featureUnsupported))
        return Progress()
    }

    // MARK: - Changes from Files

    func createItem(
        basedOn itemTemplate: NSFileProviderItem,
        fields: NSFileProviderItemFields,
        contents url: URL?,
        options: NSFileProviderCreateItemOptions,
        request: NSFileProviderRequest,
        completionHandler: @escaping (NSFileProviderItem?, NSFileProviderItemFields, Bool, (any Error)?) -> Void
    ) -> Progress {
        MEGALogError("[Picker] createItem is not supported yet: \(itemTemplate.filename) in \(itemTemplate.parentItemIdentifier.rawValue)")
        completionHandler(nil, [], false, CocoaError(.featureUnsupported))
        return Progress()
    }

    func modifyItem(
        _ item: NSFileProviderItem,
        baseVersion version: NSFileProviderItemVersion,
        changedFields: NSFileProviderItemFields,
        contents newContents: URL?,
        options: NSFileProviderModifyItemOptions,
        request: NSFileProviderRequest,
        completionHandler: @escaping (NSFileProviderItem?, NSFileProviderItemFields, Bool, (any Error)?) -> Void
    ) -> Progress {
        MEGALogError("[Picker] modifyItem is not supported yet: \(item.itemIdentifier.rawValue), fields \(changedFields.rawValue)")
        completionHandler(nil, [], false, CocoaError(.featureUnsupported))
        return Progress()
    }

    func deleteItem(
        identifier: NSFileProviderItemIdentifier,
        baseVersion version: NSFileProviderItemVersion,
        options: NSFileProviderDeleteItemOptions,
        request: NSFileProviderRequest,
        completionHandler: @escaping ((any Error)?) -> Void
    ) -> Progress {
        MEGALogError("[Picker] deleteItem is not supported yet: \(identifier.rawValue)")
        completionHandler(CocoaError(.featureUnsupported))
        return Progress()
    }

    // MARK: - Enumeration

    func enumerator(
        for containerItemIdentifier: NSFileProviderItemIdentifier,
        request: NSFileProviderRequest
    ) throws -> any NSFileProviderEnumerator {
        // A domain can outlive the session, e.g. when the app is killed before its logout removed the domain.
        guard credentialUseCase.hasSession() else {
            throw NSError(domain: NSFileProviderErrorDomain, code: NSFileProviderError.notAuthenticated.rawValue)
        }
        guard !credentialUseCase.isPasscodeEnabled() else {
            throw FileProviderSession.passcodeEnabledError
        }
        return ReplicatedFileProviderEnumerator(containerIdentifier: containerItemIdentifier, itemUseCase: itemUseCase)
    }

    // MARK: - Private

    private func copyDatabasesFromMainApp() {
        CopyDataBasesUseCase(repo: CopyDataBasesRepository.nodeDatabaseGatedRepo).copyFromMainApp { result in
            switch result {
            case .success:
                MEGALogDebug("[Picker] Databases from main app copied")
            case .failure(let error):
                MEGALogError("[Picker] Error copying databases from main app: \(error)")
            }
        }
    }
}

/// Carries a completion handler from the system into a `Task`. The system never calls the handler itself and the
/// task calls it exactly once, so it is never used concurrently even though its type is not `Sendable`.
struct UncheckedSendableCompletion<Handler>: @unchecked Sendable {
    let handler: Handler

    init(_ handler: Handler) {
        self.handler = handler
    }
}
