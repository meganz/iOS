import MEGADomain

package enum FileLinkFlowErrorEntity: Error, Sendable, Equatable {
    case linkUnavailable(LinkUnavailableReason) // to show error page
    case invalidDecryptionKey // to show alert saying decryption key is invalid
    case missingDecryptionKey // to show alert asking for decryption key
}

package protocol FileLinkFlowUseCaseProtocol: Sendable {
    func initialStart(with link: String) async throws(FileLinkFlowErrorEntity) -> NodeEntity
    func confirmDecryptionKey(with link: String, decryptionKey: String) async throws(FileLinkFlowErrorEntity) -> NodeEntity
}

/// This handles the file link flow: resolve the public node the link points at, so the screen can show
/// the file behind it.
/// When first opening the file link, initialStart(with:) is used. If missingDecryptionKey error is
/// returned, confirmDecryptionKey(with:decryptionKey:) is used.
package struct FileLinkFlowUseCase: FileLinkFlowUseCaseProtocol {
    private let fileLinkRepository: any FileLinkRepositoryProtocol
    private let fileLinkBuilder: any FileLinkBuilderProtocol

    package init(
        fileLinkRepository: some FileLinkRepositoryProtocol = FileLinkRepository.newRepo,
        fileLinkBuilder: some FileLinkBuilderProtocol
    ) {
        self.fileLinkRepository = fileLinkRepository
        self.fileLinkBuilder = fileLinkBuilder
    }

    /// In this flow, an invalid decryption key means the key came embedded in the link itself, so
    /// the error page is shown immediately (.linkUnavailable(.generic)).
    /// Check the confirmDecryptionKey flow for the difference.
    package func initialStart(with link: String) async throws(FileLinkFlowErrorEntity) -> NodeEntity {
        do {
            return try await fileLinkRepository.publicNode(for: link)
        } catch {
            throw switch error {
            case .invalidDecryptionKey: .linkUnavailable(.generic)
            case .missingDecryptionKey: .missingDecryptionKey
            case let .linkUnavailable(reason): .linkUnavailable(reason)
            }
        }
    }

    /// In this flow, unlike the initialStart flow, an invalid decryption key does not show the error
    /// page. The user typed the key in, so they are told it is invalid and asked for it again.
    package func confirmDecryptionKey(with link: String, decryptionKey: String) async throws(FileLinkFlowErrorEntity) -> NodeEntity {
        let fullLink = await fileLinkBuilder.build(link: link, with: decryptionKey)

        do {
            return try await fileLinkRepository.publicNode(for: fullLink)
        } catch {
            throw switch error {
            case .invalidDecryptionKey: .invalidDecryptionKey
            case .missingDecryptionKey: .missingDecryptionKey
            case let .linkUnavailable(reason): .linkUnavailable(reason)
            }
        }
    }
}
