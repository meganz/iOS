import Foundation
@testable import MEGA
import MEGADomain

final class MockExportFileUseCase: ExportFileUseCaseProtocol, @unchecked Sendable {
    var exportNode_calledTimes = 0
    var exportNodes_calledTimes = 0
    var exportFolder_calledTimes = 0
    var exportMessages_calledTimes = 0
    var exportNodeFromMessage_calledTimes = 0
    /// Every folder the view model asked to have cleared, in call order.
    var removedTemporaryExportFolders: [URL] = []
    /// Run inside every export, before it returns, so a test can act while one is still in flight.
    var onExport: (@Sendable () async -> Void)?
    /// Every folder `cleanUp` was given, as it arrives. The view model clears the happy path's folder in a
    /// task of its own, so the share sheet's completion returns before the clean up has run and a test has
    /// to wait for it rather than read `removedTemporaryExportFolders` straight away.
    let cleanUpUpdates: AsyncStream<URL>
    private let cleanUpContinuation: AsyncStream<URL>.Continuation

    var exportNodeResult: ExportedSelectionEntity?
    var exportNodesResult: ExportedSelectionEntity
    var exportFolderResult: ExportedSelectionEntity?
    var exportMessagesResult: ExportedSelectionEntity
    var exportNodeFromMessageResult: ExportedSelectionEntity?

    init(
        exportNodeResult: ExportedSelectionEntity? = nil,
        exportNodesResult: ExportedSelectionEntity = .nothing,
        exportFolderResult: ExportedSelectionEntity? = nil,
        exportMessagesResult: ExportedSelectionEntity = .nothing,
        exportNodeFromMessageResult: ExportedSelectionEntity? = nil
    ) {
        self.exportNodeResult = exportNodeResult
        self.exportNodesResult = exportNodesResult
        self.exportFolderResult = exportFolderResult
        self.exportMessagesResult = exportMessagesResult
        self.exportNodeFromMessageResult = exportNodeFromMessageResult
        (cleanUpUpdates, cleanUpContinuation) = AsyncStream.makeStream(of: URL.self)
    }

    func export(node: NodeEntity) async throws -> ExportedSelectionEntity {
        exportNode_calledTimes += 1
        await onExport?()
        if let result = exportNodeResult {
            return result
        } else {
            throw ExportFileErrorEntity.downloadFailed
        }
    }
    
    func export(nodes: [NodeEntity]) async throws -> ExportedSelectionEntity {
        exportNodes_calledTimes += 1
        await onExport?()
        return exportNodesResult
    }

    func exportFolder(_ node: NodeEntity) async throws -> ExportedSelectionEntity {
        exportFolder_calledTimes += 1
        await onExport?()
        if let result = exportFolderResult {
            return result
        } else {
            throw ExportFileErrorEntity.downloadFailed
        }
    }

    func cleanUp(for selection: ExportedSelectionEntity) async {
        guard let folder = selection.temporaryFolder else { return }
        removedTemporaryExportFolders.append(folder)
        cleanUpContinuation.yield(folder)
    }

    func export(messages: [ChatMessageEntity], chatId: HandleEntity) async -> ExportedSelectionEntity {
        exportMessages_calledTimes += 1
        await onExport?()
        return exportMessagesResult
    }
    
    func exportNode(_ node: NodeEntity, messageId: HandleEntity, chatId: HandleEntity) async throws -> ExportedSelectionEntity {
        exportNodeFromMessage_calledTimes += 1
        await onExport?()
        if let result = exportNodeFromMessageResult {
            return result
        } else {
            throw ExportFileErrorEntity.downloadFailed
        }
    }
}
