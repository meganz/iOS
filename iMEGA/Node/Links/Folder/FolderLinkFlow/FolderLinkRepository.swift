import MEGADomain
import MEGASdk
import MEGASDKRepo

protocol FolderLinkRepositoryProtocol: RepositoryProtocol, Sendable {
    func loginTo(link: String) async throws
    func logout()
    func fetchNodes() async throws
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
            sdk.login(toFolderLink: link, delegate: RequestDelegate { result in
                switch result {
                case .success:
                    continuation.resume()
                case let .failure(error):
                    if error.hasExtraInfo {
                        let reason: FolderLinkUnavailableReason = if error.linkStatus == .downETD {
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
    
    func fetchNodes() async throws {
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
                        let reason: FolderLinkUnavailableReason = if error.linkStatus == .downETD {
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
    
    func logout() {
        sdk.logout()
    }
}
