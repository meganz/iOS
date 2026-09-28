@preconcurrency import FileProvider
import MEGAAppSDKRepo
import MEGADomain
import MEGARepo

/// Entry point of the File Provider extension on `NSFileProviderReplicatedExtension`.
///
/// Only used when the `MEGA_FILE_PROVIDER_PRINCIPAL_CLASS` build setting points at it; `FileProviderExtension`
/// stays the shipping implementation until the switch. For now it only serves an empty root.
final class ReplicatedFileProviderExtension: NSObject, NSFileProviderReplicatedExtension {
    private let domain: NSFileProviderDomain
    private let credentialUseCase = CredentialUseCase(repo: CredentialRepository.newRepo)

    // Nothing here may create `MEGASdk.shared`: the node databases have to be copied from the main app before
    // the SDK opens them. Any SDK-backed property added later must be lazy.
    init(domain: NSFileProviderDomain) {
        self.domain = domain
        super.init()
        AppEnvironmentConfigurator.configAppEnvironment()
#if DEBUG
        MEGASdk.setLogLevel(.max)
#endif
        MEGASdk.setLogToConsole(true)
        MEGALogDebug("[Picker] Replicated extension started for domain \(domain.identifier.rawValue)")
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
        if identifier == .rootContainer {
            completionHandler(ReplicatedFileProviderRootItem(), nil)
        } else {
            completionHandler(nil, NSError.fileProviderErrorForNonExistentItem(withIdentifier: identifier))
        }
        return Progress()
    }

    func fetchContents(
        for itemIdentifier: NSFileProviderItemIdentifier,
        version requestedVersion: NSFileProviderItemVersion?,
        request: NSFileProviderRequest,
        completionHandler: @escaping (URL?, NSFileProviderItem?, (any Error)?) -> Void
    ) -> Progress {
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
        guard containerItemIdentifier == .rootContainer || containerItemIdentifier == .workingSet else {
            throw NSError.fileProviderErrorForNonExistentItem(withIdentifier: containerItemIdentifier)
        }
        return ReplicatedFileProviderEnumerator()
    }
}
