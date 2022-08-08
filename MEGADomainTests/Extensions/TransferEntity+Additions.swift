import Foundation
@testable import MEGA
import MEGADomain

extension TransferEntity {
    init(speed: Int, totalSize: Int) {
        self.init(type: .download, transferString: nil, startTime: nil, transferredBytes: 0, totalBytes: totalSize, path: nil, parentPath: nil, nodeHandle: 0, parentHandle: 0, startPos: nil, endPos: nil, fileName: nil, numRetry: 0, maxRetries: 0, tag: 0, speed: speed, deltaSize: nil, updateTime: nil, publicNode: nil, isStreamingTransfer: true, isForeignOverquota: false, lastErrorExtended: nil, isFolderTransfer: true, folderTransferTag: 0, appData: nil, state: .active, priority: 0, stage: .none)
    }
    
    init(type: TransferTypeEntity, path: String) {
        self.init(type: type, transferString: nil, startTime: nil, transferredBytes: 0, totalBytes: 0, path: path, parentPath: nil, nodeHandle: 0, parentHandle: 0, startPos: nil, endPos: nil, fileName: nil, numRetry: 0, maxRetries: 0, tag: 0, speed: 0, deltaSize: nil, updateTime: nil, publicNode: nil, isStreamingTransfer: true, isForeignOverquota: false, lastErrorExtended: nil, isFolderTransfer: true, folderTransferTag: 0, appData: nil, state: .active, priority: 0, stage: .none)
    }
}
