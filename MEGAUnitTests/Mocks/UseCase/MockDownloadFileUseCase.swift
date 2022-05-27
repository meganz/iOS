@testable import MEGA

final class MockDownloadFileUseCase: DownloadFileUseCaseProtocol {
    var tempImagePath: String = ""
    var tempPath: String = NSTemporaryDirectory()
    var transferEntity: TransferEntity? = nil
    var result: (Result<TransferEntity, TransferErrorEntity>)? = nil
    
    func download(nodeHandle: MEGAHandle, to path: String, appData: String?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        guard let result = result else { return }
        completion(result)
    }
    
    func downloadToTempFolder(nodeHandle: MEGAHandle, appData: String?, progress: ((TransferEntity) -> Void)?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        downloadTo(folderPath: tempPath, nodeHandle: nodeHandle, appData: appData, progress: progress) { result in
            completion(result)
        }
    }
    
    func downloadTo(folderPath: String, nodeHandle: MEGAHandle, appData: String?, progress: ((TransferEntity) -> Void)?, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        guard let transferEntity = transferEntity,
              let progress = progress else { return }
        progress(transferEntity)
        guard let result = result else { return }
        completion(result)
    }
}
