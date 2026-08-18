import MEGADomain

package enum FileLinkFlowErrorEntity: Error, Sendable, Equatable {
    case linkUnavailable(LinkUnavailableReason) // to show error page
    case invalidDecryptionKey // to show alert saying decryption key is invalid
    case missingDecryptionKey // to show alert asking for decryption key
}

/// The file behind a link, together with the link it resolved from.
///
/// The two travel together because they can differ: a link shared without its key resolves through the one
/// rebuilt around the key the user typed in, and that is the only one anything downstream can use.
package struct ResolvedFileLinkEntity: Equatable, Sendable {
    package let node: NodeEntity
    package let link: String

    package init(node: NodeEntity, link: String) {
        self.node = node
        self.link = link
    }
}

package protocol FileLinkFlowUseCaseProtocol: Sendable {
    func initialStart(with link: String) async throws(FileLinkFlowErrorEntity) -> ResolvedFileLinkEntity
    func confirmDecryptionKey(
        with link: String,
        decryptionKey: String
    ) async throws(FileLinkFlowErrorEntity) -> ResolvedFileLinkEntity
}

/// This handles the file link flow: resolve the public node the link points at, so the screen can show
/// the file behind it.
/// When first opening the file link, initialStart(with:) is used. If missingDecryptionKey error is
/// returned, confirmDecryptionKey(with:decryptionKey:) is used.
package struct FileLinkFlowUseCase: FileLinkFlowUseCaseProtocol {
    private let fileLinkRepository: any FileLinkRepositoryProtocol
    private let fileLinkBuilder: any FileLinkBuilderProtocol

    /// The repository is not defaulted on purpose: it has to be built around the same
    /// `FileLinkNodeProvider` the preview loader reads from.
    package init(
        fileLinkRepository: some FileLinkRepositoryProtocol,
        fileLinkBuilder: some FileLinkBuilderProtocol
    ) {
        self.fileLinkRepository = fileLinkRepository
        self.fileLinkBuilder = fileLinkBuilder
    }

    /// In this flow, an invalid decryption key means the key came embedded in the link itself, so
    /// the error page is shown immediately (.linkUnavailable(.generic)).
    /// Check the confirmDecryptionKey flow for the difference.
    package func initialStart(with link: String) async throws(FileLinkFlowErrorEntity) -> ResolvedFileLinkEntity {
        do {
            let node = try await fileLinkRepository.publicNode(for: link)
            return ResolvedFileLinkEntity(node: node, link: link)
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
    /// Reports `fullLink` rather than the link it was asked with: the one the user was given carries no key,
    /// so it is of no use to whatever the screen does with the file next.
    package func confirmDecryptionKey(
        with link: String,
        decryptionKey: String
    ) async throws(FileLinkFlowErrorEntity) -> ResolvedFileLinkEntity {
        let fullLink = await fileLinkBuilder.build(link: link, with: decryptionKey)

        do {
            let node = try await fileLinkRepository.publicNode(for: fullLink)
            return ResolvedFileLinkEntity(node: node, link: fullLink)
        } catch {
            throw switch error {
            case .invalidDecryptionKey: .invalidDecryptionKey
            case .missingDecryptionKey: .missingDecryptionKey
            case let .linkUnavailable(reason): .linkUnavailable(reason)
            }
        }
    }
}
