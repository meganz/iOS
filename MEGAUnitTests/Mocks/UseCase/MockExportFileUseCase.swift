@testable import MEGA
import MEGADomain

final class MockExportFileUseCase: ExportFileUseCaseProtocol, @unchecked Sendable {
    var exportNode_calledTimes = 0
    var exportNodes_calledTimes = 0
    var exportMessages_calledTimes = 0
    var exportNodeFromMessage_calledTimes = 0

    var exportNodeResult: URL?
    var exportNodesResult: [URL]
    var exportMessagesResult: [URL]
    var exportNodeFromMessageResult: URL?

    init(
        exportNodeResult: URL? = nil,
        exportNodesResult: [URL] = [],
        exportMessagesResult: [URL] = [],
        exportNodeFromMessageResult: URL? = nil
    ) {
        self.exportNodeResult = exportNodeResult
        self.exportNodesResult = exportNodesResult
        self.exportMessagesResult = exportMessagesResult
        self.exportNodeFromMessageResult = exportNodeFromMessageResult
    }

    func export(node: NodeEntity) async throws -> URL {
        exportNode_calledTimes += 1
        if let result = exportNodeResult {
            return result
        } else {
            throw ExportFileErrorEntity.downloadFailed
        }
    }
    
    func export(nodes: [NodeEntity]) async throws -> [URL] {
        exportNodes_calledTimes += 1
        return exportNodesResult
    }
    
    func export(messages: [ChatMessageEntity], chatId: HandleEntity) async -> [URL] {
        exportMessages_calledTimes += 1
        return exportMessagesResult
    }
    
    func exportNode(_ node: NodeEntity, messageId: HandleEntity, chatId: HandleEntity) async throws -> URL {
        exportNodeFromMessage_calledTimes += 1
        if let result = exportNodeFromMessageResult {
            return result
        } else {
            throw ExportFileErrorEntity.downloadFailed
        }
    }
}
