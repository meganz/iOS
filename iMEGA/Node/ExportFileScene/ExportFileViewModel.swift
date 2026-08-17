import Foundation
import MEGAAppPresentation
import MEGADomain

enum ExportFileAction: ActionType {
    case exportFileFromNode(NodeEntity)
    case exportFilesFromNodes([NodeEntity])
    case exportFilesFromMessages([ChatMessageEntity], HandleEntity)
    case exportFileFromMessageNode(MEGANode, HandleEntity, HandleEntity)
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
        switch action {
        case let .exportFileFromNode(node):
            await performExport(
                requestedCount: 1,
                exportBlock: {
                    let url = try await exportFileUseCase.export(node: node)
                    return [url]
                },
                errorMessage: "[ExportFile] Failed to export file from node"
            )
        case let .exportFilesFromNodes(nodes):
            await performExport(
                requestedCount: nodes.count,
                exportBlock: {
                    return try await exportFileUseCase.export(nodes: nodes)
                },
                errorMessage: "[ExportFile] Failed to export nodes"
            )
        case let .exportFilesFromMessages(messages, chatId):
            await performExport(
                requestedCount: messages.count,
                exportBlock: {
                    return await exportFileUseCase.export(
                        messages: messages,
                        chatId: chatId
                    )
                },
                errorMessage: "[ExportFile] Failed to export files from messages"
            )
        case let .exportFileFromMessageNode(node, messageId, chatId):
            await performExport(
                requestedCount: 1,
                exportBlock: {
                    let url = try await exportFileUseCase.exportNode(
                        node.toNodeEntity(),
                        messageId: messageId,
                        chatId: chatId
                    )
                    return [url]
                },
                errorMessage: "[ExportFile] Failed to export file from a message node"
            )
        }
    }
    
    /// - Parameter requestedCount: How many files the action asked for. `exportBlock` drops whatever it
    ///   could not fetch rather than throwing, so this is the only way to tell a partial result from a
    ///   complete one.
    private func performExport(
        requestedCount: Int,
        exportBlock: () async throws -> [URL],
        errorMessage: String
    ) async {
        guard !Task.isCancelled else { return }
        do {
            let urls = try await exportBlock()
            guard !Task.isCancelled else { return }

            await warnIfIncomplete(downloadedCount: urls.count, requestedCount: requestedCount)

            if urls.isEmpty {
                MEGALogError(errorMessage)
            } else if !Task.isCancelled {
                analyticsEventUseCase.sendAnalyticsEvent(.download(.exportFile))
                router.exportedFiles(urls: urls)
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
