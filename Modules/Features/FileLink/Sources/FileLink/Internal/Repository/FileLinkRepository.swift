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
    static package var newRepo: FileLinkRepository {
        FileLinkRepository(sdk: .sharedSdk)
    }

    private let sdk: MEGASdk

    package init(sdk: MEGASdk) {
        self.sdk = sdk
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
