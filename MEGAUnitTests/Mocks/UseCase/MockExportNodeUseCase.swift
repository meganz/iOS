import MEGADomain

final class MockExportNodeUseCase: ExportFileUseCaseProtocol {
    
    var exportResult: (Result<URL, ExportFileErrorEntity>) = .failure(.generic)
    var exportUrlsResult: [URL] = []
    var exportFromChatResult: (Result<URL, ExportFileErrorEntity>) = .failure(.generic)
    
    func export(node: NodeEntity, completion: @escaping (Result<URL, ExportFileErrorEntity>) -> Void) {
        completion(exportResult)
    }
    
    func export(nodes: [NodeEntity], completion: @escaping ([URL]) -> Void) {
        completion(exportUrlsResult)
    }
    
    func export(message: MEGAChatMessage, chatId: HandleEntity, completion: @escaping (Result<URL, ExportFileErrorEntity>) -> Void) {
        completion(exportFromChatResult)
    }
    
    func export(messages: [MEGAChatMessage], chatId: HandleEntity, completion: @escaping ([URL]) -> Void) {
        completion(exportUrlsResult)
    }
    
    func exportNode(_ node: NodeEntity, messageId: HandleEntity, chatId: HandleEntity, completion: @escaping (Result<URL, ExportFileErrorEntity>) -> Void) {
        completion(exportFromChatResult)
    }
}
