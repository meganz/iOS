@testable import MEGA
import MEGADomain

final class MockUploadFileUseCase: UploadFileUseCaseProtocol {
    var duplicate: Bool = true
    var newName: String?
    var uploadFileResult: (Result<Void, TransferErrorEntity>)? = nil
    var uploadSupportFileResult: (Result<TransferEntity, TransferErrorEntity>)? = nil
    var cancelTransferResult: (Result<Void, TransferErrorEntity>) = .failure(.generic)
    
    
    func hasExistFile(name: String, parentHandle: HandleEntity) -> Bool {
        newName = name
        return duplicate
    }
    
    func uploadFile(withLocalPath path: String, toParent parent: HandleEntity, fileName: String?, appData: String?, isSourceTemporary: Bool, startFirst: Bool, cancelToken: MEGACancelToken?, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: ((Result<Void, TransferErrorEntity>) -> Void)?)
    {
        guard let result = uploadFileResult else { return }
        completion?(result)
    }
    
    func uploadSupportFile(atPath path: String, start: @escaping (TransferEntity) -> Void, progress: @escaping (TransferEntity) -> Void, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        guard let result = uploadSupportFileResult else { return }
        completion(result)
    }
    
    func cancel(transfer: TransferEntity, completion: @escaping (Result<Void, TransferErrorEntity>) -> Void) {
        completion(cancelTransferResult)
    }
}
