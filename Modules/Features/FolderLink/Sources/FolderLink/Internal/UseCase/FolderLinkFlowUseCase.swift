import MEGADomain

package enum LinkUnavailableReason: Error, Sendable, Equatable {
    case downETD
    case userETDSuspension
    case copyrightSuspension
    case generic
    case expired
}

package enum FolderLinkFlowErrorEntity: Error, Sendable, Equatable {
    case linkUnavailable(LinkUnavailableReason) // to show error page
    case invalidDecryptionKey // to show alert saying decryption key is invalid
    case missingDecryptionKey // to show alert asking for decryption key
}

package protocol FolderLinkFlowUseCaseProtocol: Sendable {
    func initialStart(with link: String) async throws(FolderLinkFlowErrorEntity) -> HandleEntity
    func confirmDecryptionKey(with link: String, decryptionKey: String) async throws(FolderLinkFlowErrorEntity) -> HandleEntity
    func stop()
}

public protocol FolderLinkBuilderProtocol: Sendable {
    func build(link: String, with key: String) async -> String
}

/// This handle the folder link flow: Login in to folder link -> fetchNodes to have the nodes are available -> get the root folder link node
/// When first opening the folder link, the initialStart(with:) is used. If missingDecryptionKey error is returned, confirmDecryptionKey(with:decryptionKey:) is used
package struct FolderLinkFlowUseCase: FolderLinkFlowUseCaseProtocol {
    private let folderLinkLoginUseCase: any FolderLinkLoginUseCaseProtocol
    private let folderLinkLogoutUseCase: any FolderLinkLogoutUseCaseProtocol
    private let folderLinkFetchNodesUseCase: any FolderLinkFetchNodesUseCaseProtocol
    private let folderLinkSearchUseCase: any FolderLinkSearchUseCaseProtocol
    private let folderLinkBuilder: any FolderLinkBuilderProtocol
    
    package init(
        folderLinkLoginUseCase: some FolderLinkLoginUseCaseProtocol = FolderLinkLoginUseCase(),
        folderLinkLogoutUseCase: some FolderLinkLogoutUseCaseProtocol = FolderLinkLogoutUseCase(),
        folderLinkFetchNodesUseCase: some FolderLinkFetchNodesUseCaseProtocol = FolderLinkFetchNodesUseCase(),
        folderLinkSearchUseCase: some FolderLinkSearchUseCaseProtocol = FolderLinkSearchUseCase(),
        folderLinkBuilder: some FolderLinkBuilderProtocol
    ) {
        self.folderLinkLoginUseCase = folderLinkLoginUseCase
        self.folderLinkFetchNodesUseCase = folderLinkFetchNodesUseCase
        self.folderLinkSearchUseCase = folderLinkSearchUseCase
        self.folderLinkBuilder = folderLinkBuilder
        self.folderLinkLogoutUseCase = folderLinkLogoutUseCase
    }
    
    /// In this flow, if invalidDecryptionKey error is returned, error page is shown immediately (.linkUnavailable(.generic))
    /// Check confirmDecryptionKey flow for difference
    package func initialStart(with link: String) async throws(FolderLinkFlowErrorEntity) -> HandleEntity {
        do {
            try await folderLinkLoginUseCase.login(to: link)
            try await folderLinkFetchNodesUseCase.fetchNodes()
            return folderLinkSearchUseCase.rootFolderLink()
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
    package func confirmDecryptionKey(with link: String, decryptionKey: String) async throws(FolderLinkFlowErrorEntity) -> HandleEntity {
        let fullLink = await folderLinkBuilder.build(link: link, with: decryptionKey)
        
        do {
            try await folderLinkLoginUseCase.login(to: fullLink)
            try await folderLinkFetchNodesUseCase.fetchNodes()
            return folderLinkSearchUseCase.rootFolderLink()
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
    
    package func stop() {
        folderLinkLogoutUseCase.logout()
    }
}
