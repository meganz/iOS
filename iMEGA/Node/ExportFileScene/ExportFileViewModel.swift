import Foundation
import MEGAAppPresentation
import MEGADomain

enum ExportFileAction: ActionType {
    case exportFileFromNode(NodeEntity)
    case exportFilesFromNodes([NodeEntity])
    case exportFilesFromMessages([ChatMessageEntity], HandleEntity)
    case exportFileFromMessageNode(MEGANode, HandleEntity, HandleEntity)
}

private extension ExportFileAction {
    /// The folder this action is about, when it is about exactly one and nothing else.
    ///
    /// A folder link exports the folder being browsed as a single node selection, which is why this looks
    /// past `exportFilesFromNodes` as well as at the single node case.
    var singleFolderNode: NodeEntity? {
        let node: NodeEntity? = switch self {
        case let .exportFileFromNode(node): node
        case let .exportFilesFromNodes(nodes): nodes.count == 1 ? nodes.first : nil
        default: nil
        }
        return node?.isFolder == true ? node : nil
    }
}

@MainActor
protocol ExportFileViewRouting {
    func exportedFiles(urls: [URL])
    func showProgressView()
    func hideProgressView()
    func warnDownloadIncomplete(downloadedCount: Int, failedCount: Int) async
}

@MainActor
final class ExportFileViewModel: ViewModelType {
    
    enum Command: CommandType, Equatable { }

    // MARK: - Private properties
    private let router: any ExportFileViewRouting
    private let exportFileUseCase: any ExportFileUseCaseProtocol
    private let analyticsEventUseCase: any AnalyticsEventUseCaseProtocol
    private let overDiskQuotaChecker: any OverDiskQuotaChecking
    private(set) var currentTask: Task<Void, Never>?

    // MARK: - Internal properties
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    init(
        router: some ExportFileViewRouting,
        analyticsEventUseCase: any AnalyticsEventUseCaseProtocol,
        exportFileUseCase: any ExportFileUseCaseProtocol,
        overDiskQuotaChecker: some OverDiskQuotaChecking
    ) {
        self.router = router
        self.analyticsEventUseCase = analyticsEventUseCase
        self.exportFileUseCase = exportFileUseCase
        self.overDiskQuotaChecker = overDiskQuotaChecker
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: ExportFileAction) {
        guard !overDiskQuotaChecker.showOverDiskQuotaIfNeeded() else { return }
        cancelCurrentTask()
        router.showProgressView()
        
        currentTask = Task {
            await executeExportAction(action)
        }
    }
    
    // MARK: - Cancel Task
    func cancelCurrentTask() {
        currentTask?.cancel()
        currentTask = nil
    }
    
    // MARK: - Private Methods
    private func executeExportAction(_ action: ExportFileAction) async {
        // A lone folder is exported on its own rather than as a selection of one. A selection carries on
        // when a node fails, which turns a cancelled download into one thing missing and warns about it;
        // alone, the cancellation propagates and a user who stopped it themselves is left alone.
        if let folder = action.singleFolderNode {
            await performExport(errorMessage: "[ExportFile] Failed to export folder") {
                // Folded through `adding` rather than built by hand, so that a folder on its own is counted
                // by exactly the rule a folder inside a selection is counted by.
                .nothing.adding(try await exportFileUseCase.exportFolder(folder))
            }
            return
        }

        switch action {
        case let .exportFileFromNode(node):
            await performExport(errorMessage: "[ExportFile] Failed to export file from node") {
                let url = try await exportFileUseCase.export(node: node)
                return ExportedSelectionEntity(urls: [url], requestedFileCount: 1, downloadedFileCount: 1)
            }
        case let .exportFilesFromNodes(nodes):
            await performExport(errorMessage: "[ExportFile] Failed to export nodes") {
                try await exportFileUseCase.export(nodes: nodes)
            }
        case let .exportFilesFromMessages(messages, chatId):
            await performExport(errorMessage: "[ExportFile] Failed to export files from messages") {
                // One URL per message, dropping whatever could not be exported, so what arrived is countable
                // from `urls` alone.
                let urls = await exportFileUseCase.export(messages: messages, chatId: chatId)
                return ExportedSelectionEntity(
                    urls: urls,
                    requestedFileCount: messages.count,
                    downloadedFileCount: urls.count
                )
            }
        case let .exportFileFromMessageNode(node, messageId, chatId):
            await performExport(errorMessage: "[ExportFile] Failed to export file from a message node") {
                let url = try await exportFileUseCase.exportNode(
                    node.toNodeEntity(),
                    messageId: messageId,
                    chatId: chatId
                )
                return ExportedSelectionEntity(urls: [url], requestedFileCount: 1, downloadedFileCount: 1)
            }
        }
    }

    private func performExport(errorMessage: String, exportBlock: () async throws -> ExportedSelectionEntity) async {
        guard !Task.isCancelled else { return }
        do {
            let selection = try await exportBlock()
            guard !Task.isCancelled else { return }

            await warnIfIncomplete(
                downloadedCount: selection.downloadedFileCount,
                requestedCount: selection.requestedFileCount
            )

            if selection.urls.isEmpty {
                MEGALogError(errorMessage)
            } else if !Task.isCancelled {
                analyticsEventUseCase.sendAnalyticsEvent(.download(.exportFile))
                router.exportedFiles(urls: selection.urls)
            }
        } catch is CancellationError {
            MEGALogError("[ExportFile] Cancelled task: \(errorMessage)")
        } catch {
            MEGALogError("[ExportFile] \(errorMessage): \(error.localizedDescription)")
        }
        router.hideProgressView()
    }

    /// Reported whether or not anything arrived, including when the whole selection failed — a batch that
    /// silently produces nothing is exactly the case worth telling the user about.
    private func warnIfIncomplete(downloadedCount: Int, requestedCount: Int) async {
        guard downloadedCount < requestedCount else { return }

        await router.warnDownloadIncomplete(
            downloadedCount: downloadedCount,
            failedCount: requestedCount - downloadedCount
        )
    }
}
