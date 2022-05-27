
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
    
    func export(message: MEGAChatMessage, completion: @escaping (Result<URL, ExportFileErrorEntity>) -> Void) {
        completion(exportFromChatResult)
    }
    
    func export(messages: [MEGAChatMessage], completion: @escaping ([URL]) -> Void) {
        completion(exportUrlsResult)
    }
    
    func exportMessageNode(_ node: MEGANode, completion: @escaping (Result<URL, ExportFileErrorEntity>) -> Void) {
        completion(exportFromChatResult)
    }
}
