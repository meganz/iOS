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

    // MARK: - Internal properties
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    init(router: some ExportFileViewRouting,
         analyticsEventUseCase: any AnalyticsEventUseCaseProtocol,
         exportFileUseCase: any ExportFileUseCaseProtocol) {
        self.router = router
        self.analyticsEventUseCase = analyticsEventUseCase
        self.exportFileUseCase = exportFileUseCase
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: ExportFileAction) {
        router.showProgressView()
        switch action {
        case .exportFileFromNode(let node):
            Task {
                await performExportFileFromNode(node)
            }
        case .exportFilesFromNodes(let nodes):
            Task {
                await performExportFilesFromNodes(nodes)
            }
        case .exportFilesFromMessages(let messages, let chatId):
            Task { 
                await performExportFilesFromMessages(messages, chatId: chatId)
            }
        case .exportFileFromMessageNode(let node, let messageId, let chatId):
            Task {
                await performExportFileFromMessageNode(node, messageId: messageId, chatId: chatId)
            }
        }
    }
    
    // MARK: - Private
    private func performExportFileFromNode(_ node: NodeEntity) async {
        do {
            let url = try await exportFileUseCase.export(node: node)
            analyticsEventUseCase.sendAnalyticsEvent(.download(.exportFile))
            router.exportedFiles(urls: [url])
            router.hideProgressView()
        } catch {
            MEGALogError("Failed to export file from node")
        }
    }
    
    private func performExportFilesFromNodes(_ nodes: [NodeEntity]) async {
        do {
            let urls = try await exportFileUseCase.export(nodes: nodes)
            if urls.isNotEmpty {
                analyticsEventUseCase.sendAnalyticsEvent(.download(.exportFile))
                router.exportedFiles(urls: urls)
                router.hideProgressView()
            } else {
                MEGALogError("Failed to export nodes")
            }
        } catch {
            MEGALogError("Failed to export nodes")
        }
    }
    
    private func performExportFilesFromMessages(_ messages: [ChatMessageEntity], chatId: HandleEntity) async {
        let urls = await exportFileUseCase.export(messages: messages, chatId: chatId)
        if urls.isNotEmpty {
            analyticsEventUseCase.sendAnalyticsEvent(.download(.exportFile))
            router.exportedFiles(urls: urls)
            router.hideProgressView()
        } else {
            MEGALogError("Failed to export nodes")
        }
    }
    
    private func performExportFileFromMessageNode(_ node: MEGANode, messageId: HandleEntity, chatId: HandleEntity) async {
        do {
            let url = try await exportFileUseCase.exportNode(node.toNodeEntity(), messageId: messageId, chatId: chatId)
            self.analyticsEventUseCase.sendAnalyticsEvent(.download(.exportFile))
            self.router.exportedFiles(urls: [url])
            self.router.hideProgressView()
        } catch {
            MEGALogError("Failed to export file from a message node")
        }
    }
}
