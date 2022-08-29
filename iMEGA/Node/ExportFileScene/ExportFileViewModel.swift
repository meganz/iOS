import Foundation
import MEGADomain

enum ExportFileAction: ActionType {
    case exportFileFromNode(NodeEntity)
    case exportFilesFromNodes([NodeEntity])
    case exportFilesFromMessages([MEGAChatMessage], HandleEntity)
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

    // MARK: - Internal properties
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    init(router: ExportFileViewRouting,
         exportFileUseCase: ExportFileUseCaseProtocol) {
        self.router = router
        self.exportFileUseCase = exportFileUseCase
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: ExportFileAction) {
        router.showProgressView()
        switch action {
        case .exportFileFromNode(let node):
            exportFileUseCase.export(node: node) { result in
                switch result {
                case .success(let url):
                    self.router.exportedFiles(urls: [url])
                    self.router.hideProgressView()
                case .failure(_):
                    break
                }
            }
        case .exportFilesFromNodes(let nodes):
            exportFileUseCase.export(nodes: nodes) { urls in
                if urls.isNotEmpty {
                    self.router.exportedFiles(urls: urls)
                    self.router.hideProgressView()
                } else {
                    MEGALogError("Failed to export nodes")
                }
            }
        case .exportFilesFromMessages(let messages, let chatId):
            exportFileUseCase.export(messages: messages, chatId: chatId) { urls in
                if urls.isNotEmpty {
                    self.router.exportedFiles(urls: urls)
                    self.router.hideProgressView()
                } else {
                    MEGALogError("Failed to export a non compatible message(s) type")
                }
            }
        case .exportFileFromMessageNode(let node, let messageId, let chatId):
            exportFileUseCase.exportNode(node.toNodeEntity(), messageId:messageId, chatId:chatId) { result in
                switch result {
                case .success(let url):
                    self.router.exportedFiles(urls: [url])
                    self.router.hideProgressView()
                case .failure(_):
                    break
                }
            }
        }
    }
}
