import MEGADomain
import MEGASdk
import MEGASDKRepo

package protocol FolderLinkRepositoryProtocol: RepositoryProtocol, Sendable {
    func loginTo(link: String) async throws
    func logout()
    func fetchNodes() async throws
    func getRootNode() -> HandleEntity
    func children(of nodeHandle: HandleEntity, order: SortOrderEntity) async -> [NodeEntity]
    func children(of nodeHandle: HandleEntity) -> [NodeEntity]
    func node(for handle: HandleEntity) -> NodeEntity?
}

struct FolderLinkRepository: FolderLinkRepositoryProtocol {
    static var newRepo: FolderLinkRepository {
        FolderLinkRepository(sdk: .sharedFolderLinkSdk)
    }
    
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func loginTo(link: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            let delegate = RequestDelegate(completion: { result in
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
                        case .apiENoent: .linkUnavailable(.generic)
                        default: .linkUnavailable(.generic)
                        }
                        continuation.resume(throwing: loginError)
                    }
                }
            })
            sdk.login(toFolderLink: link, delegate: delegate)
        }
    }
    
    func fetchNodes() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let delegate = RequestDelegate(completion: { result in
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
                        case .apiEArgs: .linkUnavailable(.generic)
                        case .apiEIncomplete: .missingDecryptionKey
                        case .apiENoent: .linkUnavailable(.generic)
                        default: .linkUnavailable(.generic)
                        }
                        continuation.resume(throwing: fetchNodesError)
                    }
                }
            })
            sdk.fetchNodes(with: delegate)
        }
    }
    
    func getRootNode() -> MEGADomain.HandleEntity {
        sdk.rootNode?.handle ?? .invalid
    }
    
    func logout() {
        sdk.logout()
    }
    
    func children(of nodeHandle: HandleEntity, order: SortOrderEntity) async -> [NodeEntity] {
        guard let node = await sdk.node(for: nodeHandle) else { return [] }
        return sdk.children(forParent: node, order: order.toMEGASortOrderType().rawValue).toNodeEntities()
    }
    
    func children(of nodeHandle: HandleEntity) -> [NodeEntity] {
        guard let node = sdk.node(forHandle: nodeHandle) else { return [] }
        return sdk.children(forParent: node).toNodeEntities()
    }
    
    func node(for handle: HandleEntity) -> NodeEntity? {
        sdk.node(forHandle: handle)?.toNodeEntity()
    }
}
