import MEGAAppSDKRepo
import MEGADomain
import MEGAPickerFileProviderDomain
import MEGAPickerFileProviderRepo
import os

/// Keeps the File Provider domain in step with the account: registered once the account's nodes are loaded,
/// removed on logout.
///
/// `NSFileProviderManager` runs each request on its own, so a logout right after a login (or the reverse) could
/// finish out of order and leave the domain registered with nobody logged in, or missing for a logged-in
/// account. Every update therefore waits for the previous one to finish.
final class FileProviderDomainUpdater: Sendable {
    static let shared = FileProviderDomainUpdater()

    private let useCase: any FileProviderDomainUseCaseProtocol
    private let lastUpdate = OSAllocatedUnfairLock<Task<Void, Never>?>(initialState: nil)

    init(useCase: some FileProviderDomainUseCaseProtocol = FileProviderDomainUseCase(repository: FileProviderDomainRepository.newRepo)) {
        self.useCase = useCase
    }

    /// Call once at launch. Every logout path goes through `Helper.logout`, which posts this notification.
    func startObservingLogout() {
        _ = NotificationCenter.default.addObserver(
            forName: .accountDidLogout,
            object: nil,
            queue: nil
        ) { [self] _ in
            removeDomains()
        }
    }

    func registerDomain() {
        enqueue("register") { useCase in
            for (code, error) in try await useCase.registerDomain() {
                MEGALogError("[FileProvider] Can't signal File Provider error \(code.rawValue) as resolved: \(error)")
            }
        }
    }

    func removeDomains() {
        enqueue("remove") { try await $0.removeDomains() }
    }

    private func enqueue(_ updateName: String, _ update: @escaping @Sendable (any FileProviderDomainUseCaseProtocol) async throws -> Void) {
        lastUpdate.withLock { lastUpdate in
            let previousUpdate = lastUpdate
            lastUpdate = Task { [useCase] in
                await previousUpdate?.value
                do {
                    try await update(useCase)
                } catch {
                    MEGALogError("[FileProvider] Can't \(updateName) the domain: \(error)")
                }
            }
        }
    }
}
