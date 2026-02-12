import MEGADomain
import MEGASdk
import MEGASDKRepo

package protocol FolderLinkRepositoryProtocol: RepositoryProtocol, Sendable {
    func loginTo(link: String) async throws
    func logout()
    func fetchNodes() async throws
    func getRootNode() -> HandleEntity
    func children(of nodeHandle: HandleEntity) -> [NodeEntity]
    func node(for handle: HandleEntity) -> NodeEntity?
    func retryPendingConnections()
}

package struct FolderLinkRepository: FolderLinkRepositoryProtocol {
    static package var newRepo: FolderLinkRepository {
        FolderLinkRepository(sdk: .sharedFolderLinkSdk)
    }
    
    private let sdk: MEGASdk
    
    package init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
   package func loginTo(link: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            sdk.login(toFolderLink: link, delegate: RequestDelegate { result in
                switch result {
                case .success:
                    continuation.resume()
                case let .failure(error):
                    if error.hasExtraInfo {
                        let reason: LinkUnavailableReason = if error.linkStatus == .downETD {
                            .downETD
                        } else if error.userStatus == .etdSuspension {
                            .userETDSuspension
                        } else if error.userStatus == .copyrightSuspension {
                            .copyrightSuspension
                        } else {
                            .generic
                        }
                        continuation.resume(throwing: FolderLinkLoginErrorEntity.linkUnavailable(reason))
                    } else {
                        let loginError: FolderLinkLoginErrorEntity = switch error.type {
                        case .apiEArgs: .invalidDecryptionKey
                        case .apiEIncomplete: .missingDecryptionKey
                        default: .linkUnavailable(.generic)
                        }
                        continuation.resume(throwing: loginError)
                    }
                }

            })
        }
    }
    
    package func fetchNodes() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            sdk.fetchNodes(with: RequestDelegate { result in
                switch result {
                case let .success(request):
                    if request.flag {
                        continuation.resume(throwing: FolderLinkFetchNodesErrorEntity.invalidDecryptionKey)
                    } else {
                        continuation.resume()
                    }
                case let .failure(error):
                    if error.hasExtraInfo {
                        let reason: LinkUnavailableReason = if error.linkStatus == .downETD {
                            .downETD
                        } else if error.userStatus == .etdSuspension {
                            .userETDSuspension
                        } else if error.userStatus == .copyrightSuspension {
                            .copyrightSuspension
                        } else {
                            .generic
                        }
                        continuation.resume(throwing: FolderLinkFetchNodesErrorEntity.linkUnavailable(reason))
                    } else {
                        let fetchNodesError: FolderLinkFetchNodesErrorEntity = switch error.type {
                        case .apiEIncomplete: .missingDecryptionKey
                        default: .linkUnavailable(.generic)
                        }
                        continuation.resume(throwing: fetchNodesError)
                    }
                }
            })
        }
    }
    
    package func getRootNode() -> MEGADomain.HandleEntity {
        sdk.rootNode?.handle ?? .invalid
    }
    
    package func logout() {
        sdk.logout()
    }
    
    package func children(of nodeHandle: HandleEntity) -> [NodeEntity] {
        guard let node = sdk.node(forHandle: nodeHandle) else { return [] }
        return sdk.children(forParent: node).toNodeEntities()
    }
    
    package func node(for handle: HandleEntity) -> NodeEntity? {
        sdk.node(forHandle: handle)?.toNodeEntity()
    }
    
    package func retryPendingConnections() {
        sdk.retryPendingConnections()
    }
}
