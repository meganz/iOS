import Foundation
import MEGADomain
import MEGAPresentation

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
}

@MainActor
final class ExportFileViewModel: ViewModelType {
    
    enum Command: CommandType, Equatable { }
    
    // MARK: - Private properties
    private let router: any ExportFileViewRouting
    private let exportFileUseCase: any ExportFileUseCaseProtocol
    private let analyticsEventUseCase: any AnalyticsEventUseCaseProtocol
    private(set) var currentTask: Task<Void, Never>?

    // MARK: - Internal properties
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    init(
        router: some ExportFileViewRouting,
        analyticsEventUseCase: any AnalyticsEventUseCaseProtocol,
        exportFileUseCase: any ExportFileUseCaseProtocol
    ) {
        self.router = router
        self.analyticsEventUseCase = analyticsEventUseCase
        self.exportFileUseCase = exportFileUseCase
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: ExportFileAction) {
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
                exportBlock: {
                    let url = try await exportFileUseCase.export(node: node)
                    return [url]
                },
                errorMessage: "[ExportFile] Failed to export file from node"
            )
        case let .exportFilesFromNodes(nodes):
            await performExport(
                exportBlock: {
                    return try await exportFileUseCase.export(nodes: nodes)
                },
                errorMessage: "[ExportFile] Failed to export nodes"
            )
        case let .exportFilesFromMessages(messages, chatId):
            await performExport(
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
    
    private func performExport(
        exportBlock: () async throws -> [URL],
        errorMessage: String
    ) async {
        guard !Task.isCancelled else { return }
        do {
            let urls = try await exportBlock()
            guard !Task.isCancelled else { return }

            if !urls.isEmpty {
                analyticsEventUseCase.sendAnalyticsEvent(.download(.exportFile))
                router.exportedFiles(urls: urls)
            } else {
                MEGALogError(errorMessage)
            }
        } catch is CancellationError {
            MEGALogError("[ExportFile] Cancelled task: \(errorMessage)")
        } catch {
            MEGALogError("[ExportFile] \(errorMessage): \(error.localizedDescription)")
        }
        router.hideProgressView()
    }
}
