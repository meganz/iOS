import Combine
import MEGADomain

@MainActor
package final class FolderLinkViewModel: ObservableObject {
    package struct Dependency {
        let link: String
        let folderLinkBuilder: any FolderLinkBuilderProtocol
        let folderLinkFlowUseCase: any FolderLinkFlowUseCaseProtocol
        
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
            self.init(link: link, folderLinkBuilder: folderLinkBuilder, folderLinkFlowUseCase: folderLinkFlowUseCase)
        }
        
        package init(
            link: String,
            folderLinkBuilder: some FolderLinkBuilderProtocol,
            folderLinkFlowUseCase: some FolderLinkFlowUseCaseProtocol
        ) {
            self.link = link
            self.folderLinkBuilder = folderLinkBuilder
            self.folderLinkFlowUseCase = folderLinkFlowUseCase
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
    
    private let dependency: FolderLinkViewModel.Dependency
    private var folderLinkFlowUseCase: any FolderLinkFlowUseCaseProtocol {
        dependency.folderLinkFlowUseCase
    }
     
    package init(
        dependency: FolderLinkViewModel.Dependency,
    ) {
        self.dependency = dependency
    }
    
    package func startLoadingFolderLink() async {
        do throws(FolderLinkFlowErrorEntity) {
            let handleEntity = try await folderLinkFlowUseCase.initialStart(with: dependency.link)
            viewState = .results(handleEntity)
        } catch {
            handleFolderLinkFlowError(error)
        }
    }
    
    package func stopLoadingFolderLink() {
        folderLinkFlowUseCase.stop()
    }
    
    package func confirmDecryptionKey(_ key: String) async {
        do throws(FolderLinkFlowErrorEntity) {
            let handleEntity = try await folderLinkFlowUseCase.confirmDecryptionKey(with: dependency.link, decryptionKey: key)
            viewState = .results(handleEntity)
        } catch {
            handleFolderLinkFlowError(error)
        }
    }
    
    package func cancelConfirmingDecryptionKey() {
        folderLinkFlowUseCase.stop()
    }
    
    package func acknowledgeInvalidDecryptionKey() {
        askingForDecryptionKey = true
    }
    
    private func handleFolderLinkFlowError(_ error: FolderLinkFlowErrorEntity) {
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
