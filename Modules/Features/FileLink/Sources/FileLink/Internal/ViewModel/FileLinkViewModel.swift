import Combine
import MEGADomain
import MEGAL10n
import MEGARepo

@MainActor
package final class FileLinkViewModel: ObservableObject {
    private enum Constants {
        /// Not localised, as in the folder link: it is the brand, not a word.
        static let brandTitle = "MEGA"
    }

    package struct Dependency {
        let link: String
        /// Set when the link the user opened was an encrypted one, of which `link` is the decrypted form.
        let encryptedLink: String?
        let fileLinkFlowUseCase: any FileLinkFlowUseCaseProtocol
        let networkUseCase: any NetworkMonitorUseCaseProtocol

        init(
            link: String,
            encryptedLink: String?,
            fileLinkBuilder: some FileLinkBuilderProtocol,
            nodeProvider: FileLinkNodeProvider
        ) {
            self.init(
                link: link,
                encryptedLink: encryptedLink,
                fileLinkFlowUseCase: FileLinkFlowUseCase(
                    fileLinkRepository: FileLinkRepository.newRepo(nodeProvider: nodeProvider),
                    fileLinkBuilder: fileLinkBuilder
                ),
                networkUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository.newRepo)
            )
        }

        package init(
            link: String,
            encryptedLink: String? = nil,
            fileLinkFlowUseCase: some FileLinkFlowUseCaseProtocol,
            networkUseCase: some NetworkMonitorUseCaseProtocol
        ) {
            self.link = link
            self.encryptedLink = encryptedLink
            self.fileLinkFlowUseCase = fileLinkFlowUseCase
            self.networkUseCase = networkUseCase
        }
    }

    package enum ViewState: Sendable, Equatable {
        case loading
        /// The link resolved. Every file stays on this screen; opening its preview, its player or any
        /// other destination is the user's move to make.
        case loaded(NodeEntity)
        case error(LinkUnavailableReason)
    }

    @Published package var viewState: ViewState = .loading
    @Published package var askingForDecryptionKey: Bool = false
    @Published package var notifyInvalidDecryptionKey: Bool = false
    /// Every action the screen offers but Share link needs the network, so the screen keeps track of it
    /// rather than letting the user find out by tapping. See `monitorNetworkConnection()`.
    @Published package private(set) var isNetworkConnected: Bool

    /// The brand carries the title until the link resolves, at which point the file takes over. This
    /// mirrors the folder link, where the unavailable state keeps the brand rather than spelling the
    /// failure out in the navigation bar.
    package var navigationTitle: String {
        if case let .loaded(node) = viewState {
            node.name
        } else {
            Constants.brandTitle
        }
    }

    /// Always names the kind of link the screen is showing.
    package var navigationSubtitle: String {
        Strings.Localizable.fileLink
    }

    /// The link to pass the file on with: the encrypted one when the user arrived through an encrypted link,
    /// since that is the form it was published in, and otherwise the link the file actually resolved from.
    ///
    /// The link the screen was opened with is the last resort rather than the first choice: a link shared
    /// without its key resolves through the one rebuilt around the key the user typed in, and handing on the
    /// keyless one would leave whoever receives it unable to open the file.
    package var shareLink: String {
        dependency.encryptedLink ?? resolvedLink ?? dependency.link
    }

    private let dependency: Dependency
    private let trackingUseCase: any FileLinkTrackingUseCaseProtocol
    private var fileLinkFlowStopped = false
    /// Kept from the moment the link resolved. See `shareLink`.
    private var resolvedLink: String?

    package init(
        dependency: Dependency,
        trackingUseCase: some FileLinkTrackingUseCaseProtocol = FileLinkTrackingUseCase()
    ) {
        self.dependency = dependency
        self.trackingUseCase = trackingUseCase
        isNetworkConnected = dependency.networkUseCase.isConnected()
    }

    /// Reported as soon as the screen is up, before the link has resolved, so that a link which never
    /// opens -- taken down, expired, or missing its key -- is counted too. `trackFileLinkOpened()` is
    /// the other half: it only fires once a file is actually on screen.
    package func trackScreenView() {
        trackingUseCase.trackScreenView()
    }

    /// Follows the connection for as long as the screen is up. The sequence never finishes, so the task
    /// the view starts this on is what ends it.
    package func monitorNetworkConnection() async {
        for await connected in dependency.networkUseCase.connectionSequence {
            isNetworkConnected = connected
        }
    }

    package func startLoadingFileLink() async {
        fileLinkFlowStopped = false
        do throws(FileLinkFlowErrorEntity) {
            let resolvedFileLink = try await dependency.fileLinkFlowUseCase.initialStart(with: dependency.link)
            show(resolvedFileLink)
        } catch {
            handleFileLinkFlowError(error)
        }
    }

    package func confirmDecryptionKey(_ key: String) async {
        fileLinkFlowStopped = false
        do throws(FileLinkFlowErrorEntity) {
            let resolvedFileLink = try await dependency.fileLinkFlowUseCase.confirmDecryptionKey(
                with: dependency.link,
                decryptionKey: key
            )
            show(resolvedFileLink)
        } catch {
            handleFileLinkFlowError(error)
        }
    }

    /// Closing the screen has to be remembered: the link keeps resolving in the background, and a
    /// result arriving afterwards must not act on a screen the user has already walked away from.
    package func stopLoadingFileLink() {
        fileLinkFlowStopped = true
    }

    package func acknowledgeInvalidDecryptionKey() {
        askingForDecryptionKey = true
    }

    /// The single point both the initial resolution and a key the user typed in come through, which is
    /// why the opened event is reported here rather than at either call site.
    private func show(_ resolvedFileLink: ResolvedFileLinkEntity) {
        guard !fileLinkFlowStopped else { return }
        resolvedLink = resolvedFileLink.link
        viewState = .loaded(resolvedFileLink.node)
        trackingUseCase.trackFileLinkOpened()
    }

    private func handleFileLinkFlowError(_ error: FileLinkFlowErrorEntity) {
        guard !fileLinkFlowStopped else { return }
        switch error {
        case .invalidDecryptionKey:
            notifyInvalidDecryptionKey = true
        case .missingDecryptionKey:
            askingForDecryptionKey = true
        case let .linkUnavailable(reason):
            viewState = .error(reason)
        }
    }
}
