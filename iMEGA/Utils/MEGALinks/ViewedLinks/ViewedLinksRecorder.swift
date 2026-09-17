import FileLink
import Foundation
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import ViewedLinks

@MainActor
final class ViewedLinksRecorder {
    static let shared = ViewedLinksRecorder()

    private let useCase: any ViewedLinksUseCaseProtocol
    private let isEnabled: @MainActor () -> Bool

    init(
        useCase: some ViewedLinksUseCaseProtocol = ViewedLinksFactory.makeUseCase(),
        isEnabled: @escaping @MainActor () -> Bool = ViewedLinksRecorder.defaultIsEnabled()
    ) {
        self.useCase = useCase
        self.isEnabled = isEnabled
    }

    /// The history belongs to a signed-in account, so a link opened without one is not recorded: the
    /// widget that shows the history is unreachable while signed out, and a row left behind would
    /// surface to whichever account signs in next.
    private static func defaultIsEnabled() -> @MainActor () -> Bool {
        let accountUseCase = AccountUseCase(repository: AccountRepository.newRepo)

        return {
            DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .iosHomeRevampPhaseTwo)
                && accountUseCase.isLoggedIn()
        }
    }

    /// Call once at launch. The history has to be dropped on logout whether or not a link was opened
    /// this session, so the observation cannot wait for the first link to bring the recorder to life.
    func startObservingLogout() {
        _ = NotificationCenter.default.addObserver(
            forName: .MEGALogout,
            object: nil,
            queue: nil
        ) { [useCase] _ in
            Task {
                try? await useCase.clearHistory()
            }
        }
    }

    func record(handle: HandleEntity, name: String, linkURL: URL, isFolder: Bool) {
        guard isEnabled(), !name.isEmpty else { return }

        let linkURL = Self.normalised(linkURL)

        let link = ViewedLinkEntity(
            handle: handle,
            linkURL: linkURL,
            name: name,
            isFolder: isFolder,
            lastAccessed: .now
        )

        Task { [useCase] in
            try? await useCase.record(link)
        }
    }

    func removeUnavailable(linkURL: URL) {
        guard isEnabled() else { return }

        let linkURL = Self.normalised(linkURL)

        Task { [useCase] in
            try? await useCase.removeUnavailable(linkURL: linkURL)
        }
    }

    /// The same link reaches us in several shapes: `mega://`, `mega.co.nz`, `www.mega.nz`. Only the
    /// plain-link path is normalised before it gets here, so a password-protected link would otherwise
    /// be stored in whatever form the user received and never match when pruned by URL.
    private static func normalised(_ url: URL) -> URL {
        URL(string: (url as NSURL).mnz_MEGAURL()) ?? url
    }
}

// MARK: - FileLinkResolutionReporting

extension ViewedLinksRecorder: FileLinkResolutionReporting {
    func linkResolved(node: NodeEntity, receivedLink: String) {
        guard let linkURL = URL(string: receivedLink) else { return }

        record(handle: node.handle, name: node.name, linkURL: linkURL, isFolder: false)
    }

    func linkUnavailable(receivedLink: String) {
        guard let linkURL = URL(string: receivedLink) else { return }

        removeUnavailable(linkURL: linkURL)
    }
}
