@testable import MEGA

final class MockDownloadFileUseCase: DownloadFileUseCaseProtocol {
    var transferEntity: TransferEntity? = nil
    var result: (Result<TransferEntity, TransferErrorEntity>)? = nil
    
    func downloadToTempFolder(nodeHandle: MEGAHandle, progress: @escaping (TransferEntity) -> Void, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        guard let transferEntity = transferEntity else { return }
        progress(transferEntity)
        guard let result = result else { return }
        completion(result)
    }
}
