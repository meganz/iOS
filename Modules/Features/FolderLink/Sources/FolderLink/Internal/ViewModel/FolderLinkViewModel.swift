import Combine
import MEGAAppSDKRepo
import MEGADomain

@MainActor
package final class FolderLinkViewModel: ObservableObject {
    package struct Dependency {
        let link: String
        let folderLinkBuilder: any FolderLinkBuilderProtocol
        let folderLinkFlowUseCase: any FolderLinkFlowUseCaseProtocol
        let pendingConnectionsRetryUseCase: any FolderLinkPendingConnectionsRetryUseCaseProtocol
        let networkUseCase: any NetworkMonitorUseCaseProtocol
        
        package init(
            link: String,
            folderLinkBuilder: some FolderLinkBuilderProtocol
        ) {
            let folderLinkFlowUseCase = FolderLinkFlowUseCase(
                folderLinkLoginUseCase: FolderLinkLoginUseCase(),
                folderLinkFetchNodesUseCase: FolderLinkFetchNodesUseCase(),
                folderLinkSearchUseCase: FolderLinkSearchUseCase(),
                folderLinkBuilder: folderLinkBuilder
            )
            self.init(
                link: link,
                folderLinkBuilder: folderLinkBuilder,
                folderLinkFlowUseCase: folderLinkFlowUseCase,
                pendingConnectionsRetryUseCase: FolderLinkPendingConnectionsRetryUseCase(),
                networkUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository.newRepo),
                
            )
        }
        
        package init(
            link: String,
            folderLinkBuilder: some FolderLinkBuilderProtocol,
            folderLinkFlowUseCase: some FolderLinkFlowUseCaseProtocol,
            pendingConnectionsRetryUseCase: some FolderLinkPendingConnectionsRetryUseCaseProtocol,
            networkUseCase: some NetworkMonitorUseCaseProtocol
        ) {
            self.link = link
            self.folderLinkBuilder = folderLinkBuilder
            self.folderLinkFlowUseCase = folderLinkFlowUseCase
            self.pendingConnectionsRetryUseCase = pendingConnectionsRetryUseCase
            self.networkUseCase = networkUseCase
        }
    }
    
    package enum ViewState: Sendable, Equatable {
        case loading
        case error(LinkUnavailableReason)
        case results(HandleEntity)
    }
    
    @Published package var viewState: ViewState = .loading
    @Published package var askingForDecryptionKey: Bool = false
    @Published package var notifyInvalidDecryptionKey: Bool = false
    @Published package var isNetworkConnected: Bool
    private var folderLinkFlowStopped = false
    private let dependency: FolderLinkViewModel.Dependency
    private var folderLinkFlowUseCase: any FolderLinkFlowUseCaseProtocol {
        dependency.folderLinkFlowUseCase
    }
     
    package init(
        dependency: FolderLinkViewModel.Dependency,
    ) {
        self.dependency = dependency
        self.isNetworkConnected = dependency.networkUseCase.isConnected()
    }
    
    package func onAppear() async {
        for await connected in dependency.networkUseCase.connectionSequence {
            isNetworkConnected = connected
        }
    }
    
    package func startLoadingFolderLink() async {
        folderLinkFlowStopped = false
        do throws(FolderLinkFlowErrorEntity) {
            let handleEntity = try await folderLinkFlowUseCase.initialStart(with: dependency.link)
            viewState = .results(handleEntity)
        } catch {
            handleFolderLinkFlowError(error)
        }
    }
    
    package func stopLoadingFolderLink() {
        folderLinkFlowStopped = true
        folderLinkFlowUseCase.stop()
    }
    
    package func confirmDecryptionKey(_ key: String) async {
        folderLinkFlowStopped = false
        do throws(FolderLinkFlowErrorEntity) {
            let handleEntity = try await folderLinkFlowUseCase.confirmDecryptionKey(with: dependency.link, decryptionKey: key)
            viewState = .results(handleEntity)
        } catch {
            handleFolderLinkFlowError(error)
        }
    }
    
    package func cancelConfirmingDecryptionKey() {
        stopLoadingFolderLink()
    }
    
    package func acknowledgeInvalidDecryptionKey() {
        askingForDecryptionKey = true
    }
    
    package func retryPendingConnections() {
        dependency.pendingConnectionsRetryUseCase.retryPendingConnections()
    }
    
    private func handleFolderLinkFlowError(_ error: FolderLinkFlowErrorEntity) {
        guard !folderLinkFlowStopped else { return }
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
