import Foundation
import MEGADomain

enum ExportFileAction: ActionType {
    case exportFileFromNode(NodeEntity)
    case exportFilesFromNodes([NodeEntity])
    case exportFilesFromMessages([ChatMessageEntity], HandleEntity)
    case exportFileFromMessageNode(MEGANode, HandleEntity, HandleEntity)
}

protocol ExportFileViewRouting {
    func exportedFiles(urls: [URL])
    func showProgressView()
    func hideProgressView()
}

final class ExportFileViewModel: ViewModelType {
    
    enum Command: CommandType, Equatable { }
    
    // MARK: - Private properties
    private let router: ExportFileViewRouting
    private let exportFileUseCase: ExportFileUseCaseProtocol
    private let analyticsEventUseCase: AnalyticsEventUseCaseProtocol

    // MARK: - Internal properties
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    init(router: ExportFileViewRouting,
         analyticsEventUseCase: AnalyticsEventUseCaseProtocol,
         exportFileUseCase: ExportFileUseCaseProtocol) {
        self.router = router
        self.analyticsEventUseCase = analyticsEventUseCase
        self.exportFileUseCase = exportFileUseCase
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: ExportFileAction) {
        router.showProgressView()
        switch action {
        case .exportFileFromNode(let node):
            exportFileUseCase.export(node: node) { result in
                if case let .success(url) = result {
                    self.analyticsEventUseCase.sendAnalyticsEvent(.download(.exportFile))
                    self.router.exportedFiles(urls: [url])
                    self.router.hideProgressView()
                }
            }
        case .exportFilesFromNodes(let nodes):
            exportFileUseCase.export(nodes: nodes) { urls in
                if urls.isNotEmpty {
                    self.analyticsEventUseCase.sendAnalyticsEvent(.download(.exportFile))
                    self.router.exportedFiles(urls: urls)
                    self.router.hideProgressView()
                } else {
                    MEGALogError("Failed to export nodes")
                }
            }
        case .exportFilesFromMessages(let messages, let chatId):
            exportFileUseCase.export(messages: messages, chatId: chatId) { urls in
                if urls.isNotEmpty {
                    self.analyticsEventUseCase.sendAnalyticsEvent(.download(.exportFile))
                    self.router.exportedFiles(urls: urls)
                    self.router.hideProgressView()
                } else {
                    MEGALogError("Failed to export a non compatible message(s) type")
                }
            }
        case .exportFileFromMessageNode(let node, let messageId, let chatId):
            exportFileUseCase.exportNode(node.toNodeEntity(), messageId:messageId, chatId:chatId) { result in
                if case let .success(url) = result {
                    self.analyticsEventUseCase.sendAnalyticsEvent(.download(.exportFile))
                    self.router.exportedFiles(urls: [url])
                    self.router.hideProgressView()
                }
            }
        }
    }
}
