import MEGADomain
import Foundation

public extension TransferEntity {
    init(type: TransferTypeEntity = .download,
         transferString: String? = nil,
         startTime: Date? = nil,
         transferredBytes: Int = 0,
         totalBytes: Int = 0,
         path: String? = nil,
         parentPath: String? = nil,
         nodeHandle: HandleEntity = .invalid,
         parentHandle: HandleEntity = .invalid,
         startPos: Int? = nil,
         endPos: Int? = nil,
         fileName: String? = nil,
         numRetry: Int = 0,
         maxRetries: Int = 0,
         tag: Int = 0,
         speed: Int = 0,
         deltaSize: Int? = nil,
         updateTime: Date? = nil,
         publicNode: NodeEntity? = nil,
         isStreamingTransfer: Bool = false,
         isFinished: Bool = false,
         isForeignOverquota: Bool = false,
         lastErrorExtended: TransferErrorEntity? = nil,
         isFolderTransfer: Bool = false,
         folderTransferTag: Int = 0,
         appData: String? = nil,
         state: TransferStateEntity = .none,
         priority: UInt64 = 0,
         stage: TransferStageEntity = .none,
         isTesting: Bool = true) {
        self.init(type: type, transferString: transferString, startTime: startTime, transferredBytes: transferredBytes, totalBytes: totalBytes, path: path, parentPath: parentPath, nodeHandle: nodeHandle, parentHandle: parentHandle, startPos: startPos, endPos: endPos, fileName: fileName, numRetry: numRetry, maxRetries: maxRetries, tag: tag, speed: speed, deltaSize: deltaSize, updateTime: updateTime, publicNode: publicNode, isStreamingTransfer: isStreamingTransfer, isFinished: isFinished, isForeignOverquota: isForeignOverquota, lastErrorExtended: lastErrorExtended, isFolderTransfer: isFolderTransfer, folderTransferTag: folderTransferTag, appData: appData, state: state, priority: priority, stage: stage)
    }
}
