import MEGADomain
import MEGASdk

enum FolderLinkFlowErrorEntity: Error, Sendable, Equatable {
    case linkUnavailable(FolderLinkUnavailableReason) // to show error page
    case invalidDecryptionKey // to show alert saying decryption key is invalid
    case missingDecryptionKey // to show alert asking for decryption key
}

protocol FolderLinkFlowUseCaseProtocol: Sendable {
    func initialStart(with link: String) async throws(FolderLinkFlowErrorEntity)
    func confirmDecryptionKey(with link: String, decryptionKey: String) async throws(FolderLinkFlowErrorEntity)
    func stop()
}

/// This handle the folder link flow: Login in to folder link -> fetchNodes to have the nodes are available -> get the root folder link node
/// When first opening the folder link, the initialStart(with:) is used. If missingDecryptionKey error is returned, confirmDecryptionKey(with:decryptionKey:) is used
struct FolderLinkFlowUseCase: FolderLinkFlowUseCaseProtocol {
    private let folderLinkLoginUseCase: any FolderLinkLoginUseCaseProtocol
    private let folderLinkLogoutUseCase: any FolderLinkLogoutUseCaseProtocol
    private let folderLinkFetchNodesUseCase: any FolderLinkFetchNodesUseCaseProtocol
    
    init(
        folderLinkLoginUseCase: some FolderLinkLoginUseCaseProtocol = FolderLinkLoginUseCase(),
        folderLinkLogoutUseCase: some FolderLinkLogoutUseCaseProtocol = FolderLinkLogoutUseCase(),
        folderLinkFetchNodesUseCase: some FolderLinkFetchNodesUseCaseProtocol = FolderLinkFetchNodesUseCase()
    ) {
        self.folderLinkLoginUseCase = folderLinkLoginUseCase
        self.folderLinkFetchNodesUseCase = folderLinkFetchNodesUseCase
        self.folderLinkLogoutUseCase = folderLinkLogoutUseCase
    }
    
    /// In this flow, if invalidDecryptionKey error is returned, error page is shown immediately (.linkUnavailable(.generic))
    /// Check confirmDecryptionKey flow for difference
    func initialStart(with link: String) async throws(FolderLinkFlowErrorEntity) {
        do {
            try await folderLinkLoginUseCase.login(to: link)
            try await folderLinkFetchNodesUseCase.fetchNodes()
        } catch let loginError as FolderLinkLoginErrorEntity {
            throw switch loginError {
            case .invalidDecryptionKey: .linkUnavailable(.generic)
            case .missingDecryptionKey: .missingDecryptionKey
            case let .linkUnavailable(reason): .linkUnavailable(reason)
            }
        } catch let fetchNodesError as FolderLinkFetchNodesErrorEntity {
            throw switch fetchNodesError {
            case .invalidDecryptionKey: .linkUnavailable(.generic)
            case .missingDecryptionKey: .missingDecryptionKey
            case let .linkUnavailable(reason): .linkUnavailable(reason)
            }
        } catch {
            throw .linkUnavailable(.generic)
        }
    }
    
    /// In this flow, if invalidDecryptionKey error is returned, unlike initialStart flow, error page is not shown
    /// Instead, alert that input decryption key is invalid, and asking for input decryption key again.
    /// Check confirmDecryptionKey flow for difference
    func confirmDecryptionKey(with link: String, decryptionKey: String) async throws(FolderLinkFlowErrorEntity) {
        let fullLink = await MEGALinkManager.buildFolderLink(link, with: decryptionKey)
        
        do {
            try await folderLinkLoginUseCase.login(to: fullLink)
            try await folderLinkFetchNodesUseCase.fetchNodes()
        } catch let loginError as FolderLinkLoginErrorEntity {
            throw switch loginError {
            case .invalidDecryptionKey: .invalidDecryptionKey
            case .missingDecryptionKey: .missingDecryptionKey
            case let .linkUnavailable(reason): .linkUnavailable(reason)
            }
        } catch let fetchNodesError as FolderLinkFetchNodesErrorEntity {
            throw switch fetchNodesError {
            case .invalidDecryptionKey: .invalidDecryptionKey
            case .missingDecryptionKey: .missingDecryptionKey
            case let .linkUnavailable(reason): .linkUnavailable(reason)
            }
        } catch {
            throw .linkUnavailable(.generic)
        }
    }
    
    func stop() {
        folderLinkLogoutUseCase.logout()
    }
}
