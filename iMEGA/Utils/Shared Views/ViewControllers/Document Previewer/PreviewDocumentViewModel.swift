import ChatRepo
import Foundation
import MEGAAppSDKRepo
import MEGADomain
import MEGAPreference
import MEGARepo

@objc @MainActor
final class PreviewDocumentViewModel: NSObject {
    private let megaNode: MEGANode?
    private let makeDownloadNodeUseCase: (MEGANode) -> any DownloadNodeUseCaseProtocol
    private let leftOffItemRecordUseCase: any LeftOffItemRecordUseCaseProtocol
    
    private var downloadNodeUseCase: (any DownloadNodeUseCaseProtocol)?
    private var downloadTask: Task<Void, Never>?

    /// - Parameter node: Already authorized by the caller when it came from a link, so it downloads with
    ///   `MEGASdk.shared` without being looked up in any tree. `nil` for a local file the caller passes by path.
    @objc init(node: MEGANode?) {
        self.megaNode = node
        self.makeDownloadNodeUseCase = { Self.makeDownloadNodeUseCase(megaNode: $0) }
        self.leftOffItemRecordUseCase = LeftOffItemsRecordUseCase.shared
    }

    /// non-@objc init for testing purpose
    init(
        node: MEGANode?,
        makeDownloadNodeUseCase: @escaping (MEGANode) -> any DownloadNodeUseCaseProtocol,
        leftOffItemRecordUseCase: some LeftOffItemRecordUseCaseProtocol
    ) {
        self.megaNode = node
        self.makeDownloadNodeUseCase = makeDownloadNodeUseCase
        self.leftOffItemRecordUseCase = leftOffItemRecordUseCase
    }
    
    @objc func start(
        onProgress: @escaping (Float) -> Void,
        onStalled: @escaping () -> Void,
        onFinish: @escaping (String) -> Void
    ) {
        guard let megaNode else { return }
        
        downloadTask?.cancel()
        let downloadNodeUseCase = makeDownloadNodeUseCase(megaNode)
        self.downloadNodeUseCase = downloadNodeUseCase
        
        let node = megaNode.toNodeEntity()
        downloadTask = Task { [downloadNodeUseCase] in
            guard let events = try? downloadNodeUseCase.downloadFileToTempFolder(
                node: node,
                appData: nil
            ) else { return }

            for await event in events {
                guard !Task.isCancelled else { return }
                switch event {
                case .update(let transfer):
                    guard transfer.totalBytes > 0 else { continue }
                    onProgress(Float(transfer.transferredBytes) / Float(transfer.totalBytes))
                case .temporaryError(_, let error):
                    guard error.type == .quotaExceeded else { continue }
                    onStalled()
                case .finish(let transfer):
                    guard let path = transfer.path else { return }
                    onFinish(path)
                    return
                default:
                    break
                }
            }
        }
    }

    @objc func cancel() {
        downloadTask?.cancel()
        downloadTask = nil
        downloadNodeUseCase?.cancelDownloadTransfers()
    }

    @objc func processLeftOffItem(page: Int, totalPages: Int) {
        guard let megaNode, let name = megaNode.name, totalPages > 0 else { return }

        let nearCompletionFraction = 0.9
        let shouldRecordLeftOffItem = Double(page) / Double(totalPages) < nearCompletionFraction
        let handle = megaNode.handle

        Task { [leftOffItemRecordUseCase] in
            if shouldRecordLeftOffItem {
                await leftOffItemRecordUseCase.record(handle: handle, name: name)
            } else {
                await leftOffItemRecordUseCase.remove(handle: handle)
            }
        }
    }

    // MARK: - Private

    private static func makeDownloadNodeUseCase(megaNode: MEGANode) -> any DownloadNodeUseCaseProtocol {
        let sdk = MEGASdk.shared
        let chatSdk = MEGAChatSdk.sharedChatSdk
        return DownloadNodeUseCase(
            downloadFileRepository: DownloadFileRepository(
                sdk: sdk,
                chatNodeProvider: ChatMEGANodeProvider(chatSdk: chatSdk, sdk: sdk),
                preresolvedNodes: [megaNode.handle: megaNode]
            ),
            fileSystemRepository: FileSystemRepository.sharedRepo,
            nodeRepository: NodeRepository.newRepo,
            nodeDataRepository: NodeDataRepository.newRepo,
            fileCacheRepository: FileCacheRepository.newRepo,
            mediaUseCase: MediaUseCase(fileSearchRepo: FilesSearchRepository.newRepo),
            preferenceRepository: PreferenceRepository.newRepo,
            chatNodeRepository: ChatNodeRepository.newRepo,
            downloadChatRepository: DownloadChatRepository.newRepo
        )
    }
}
