import MEGADomain
import MEGASdk
import MEGASDKRepo
import MEGASwift

package enum FileLinkPublicNodeErrorEntity: Error, Sendable, Equatable {
    case linkUnavailable(LinkUnavailableReason)
    case invalidDecryptionKey
    case missingDecryptionKey
}

package protocol FileLinkRepositoryProtocol: RepositoryProtocol, Sendable {
    func publicNode(for link: String) async throws(FileLinkPublicNodeErrorEntity) -> NodeEntity
}

package struct FileLinkRepository: FileLinkRepositoryProtocol {
    /// Only here to satisfy `RepositoryProtocol`. Production code goes through
    /// `newRepo(nodeProvider:)`, so that the provider the preview loader reads from is the one this
    /// repository writes to.
    static package var newRepo: FileLinkRepository {
        newRepo(nodeProvider: FileLinkNodeProvider())
    }

    static package func newRepo(nodeProvider: FileLinkNodeProvider) -> FileLinkRepository {
        FileLinkRepository(sdk: .sharedSdk, nodeProvider: nodeProvider)
    }

    private let sdk: MEGASdk
    private let nodeProvider: FileLinkNodeProvider

    package init(sdk: MEGASdk, nodeProvider: FileLinkNodeProvider) {
        self.sdk = sdk
        self.nodeProvider = nodeProvider
    }

    package func publicNode(for link: String) async throws(FileLinkPublicNodeErrorEntity) -> NodeEntity {
        do {
            // The wrapper resumes with a CancellationError when the screen goes away mid-request.
            return try await withAsyncThrowingValue { completion in
                sdk.publicNode(forMegaFileLink: link, delegate: RequestDelegate { result in
                    switch result {
                    case let .success(request):
                        // A link carrying a key the API could not use comes back as a successful
                        // request with the flag raised.
                        if request.flag {
                            completion(.failure(FileLinkPublicNodeErrorEntity.invalidDecryptionKey))
                        } else if let node = request.publicNode {
                            // Stored before resuming, so the preview request that follows finds it.
                            nodeProvider.store(node)
                            completion(.success(node.toNodeEntity()))
                        } else {
                            completion(.failure(FileLinkPublicNodeErrorEntity.linkUnavailable(.generic)))
                        }
                    case let .failure(error):
                        completion(.failure(FileLinkRepository.publicNodeError(from: error)))
                    }
                })
            }
        } catch let error as FileLinkPublicNodeErrorEntity {
            throw error
        } catch {
            throw .linkUnavailable(.generic)
        }
    }

    private static func publicNodeError(from error: MEGAError) -> FileLinkPublicNodeErrorEntity {
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
            return .linkUnavailable(reason)
        }

        return switch error.type {
        case .apiEArgs: .invalidDecryptionKey
        case .apiEIncomplete: .missingDecryptionKey
        case .apiEExpired: .linkUnavailable(.expired)
        default: .linkUnavailable(.generic)
        }
    }
}
