import Combine
import MEGADomain

@MainActor
package final class FileLinkViewModel: ObservableObject {
    package struct Dependency {
        let link: String
        let fileLinkFlowUseCase: any FileLinkFlowUseCaseProtocol

        init(
            link: String,
            fileLinkBuilder: some FileLinkBuilderProtocol
        ) {
            self.init(
                link: link,
                fileLinkFlowUseCase: FileLinkFlowUseCase(fileLinkBuilder: fileLinkBuilder)
            )
        }

        package init(
            link: String,
            fileLinkFlowUseCase: some FileLinkFlowUseCaseProtocol
        ) {
            self.link = link
            self.fileLinkFlowUseCase = fileLinkFlowUseCase
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

    private let dependency: Dependency
    private var fileLinkFlowStopped = false

    package init(dependency: Dependency) {
        self.dependency = dependency
    }

    package func startLoadingFileLink() async {
        fileLinkFlowStopped = false
        do throws(FileLinkFlowErrorEntity) {
            let node = try await dependency.fileLinkFlowUseCase.initialStart(with: dependency.link)
            show(node)
        } catch {
            handleFileLinkFlowError(error)
        }
    }

    package func confirmDecryptionKey(_ key: String) async {
        fileLinkFlowStopped = false
        do throws(FileLinkFlowErrorEntity) {
            let node = try await dependency.fileLinkFlowUseCase.confirmDecryptionKey(
                with: dependency.link,
                decryptionKey: key
            )
            show(node)
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

    private func show(_ node: NodeEntity) {
        guard !fileLinkFlowStopped else { return }
        viewState = .loaded(node)
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
