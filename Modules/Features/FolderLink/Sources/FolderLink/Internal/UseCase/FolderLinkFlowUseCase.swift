import MEGADomain

package enum FolderLinkFlowErrorEntity: Error, Sendable, Equatable {
    case linkUnavailable(LinkUnavailableReason) // to show error page
    case invalidDecryptionKey // to show alert saying decryption key is invalid
    case missingDecryptionKey // to show alert asking for decryption key
}

package protocol FolderLinkFlowUseCaseProtocol: Sendable {
    func initialStart(with link: String) async throws(FolderLinkFlowErrorEntity) -> NodeEntity
    func confirmDecryptionKey(with link: String, decryptionKey: String) async throws(FolderLinkFlowErrorEntity) -> NodeEntity
    func stop(shouldLogout: Bool)
}

/// This handle the folder link flow: Login in to folder link -> fetchNodes to have the nodes are available -> get the root folder link node
/// When first opening the folder link, the initialStart(with:) is used. If missingDecryptionKey or invalidDecryptionKey error is returned, confirmDecryptionKey(with:decryptionKey:) is used
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
    
    /// An invalid key embedded in the link is reported as such rather than as an unavailable link: the
    /// folder still exists, so the user is offered to type the right key in, as on the web client.
    package func initialStart(with link: String) async throws(FolderLinkFlowErrorEntity) -> NodeEntity {
        do {
            try await folderLinkLoginUseCase.login(to: link)
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

        return try rootFolderLink()
    }
    
    /// An invalid key the user typed in is reported so they can be asked for it again.
    package func confirmDecryptionKey(with link: String, decryptionKey: String) async throws(FolderLinkFlowErrorEntity) -> NodeEntity {
        let fullLink = await folderLinkBuilder.build(link: link, with: decryptionKey)
        
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

        return try rootFolderLink()
    }
    
    package func stop(shouldLogout: Bool) {
        guard shouldLogout else { return }
        folderLinkLogoutUseCase.logout()
    }

    private func rootFolderLink() throws(FolderLinkFlowErrorEntity) -> NodeEntity {
        // in practice at the point rootFolderLink() is called,
        // folderLinkSearchUseCase.rootFolderLink() should already be available
        // If the `rootFolderLink()` is not available at this point
        // then it's an unknown error so we throw error with `.generic` reason
        guard let rootNode = folderLinkSearchUseCase.rootFolderLink() else {
            throw .linkUnavailable(.generic)
        }
        return rootNode
    }
}
