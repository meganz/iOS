@testable import MEGA

final class MockUploadFileUseCase: UploadFileUseCaseProtocol {
    var duplicate: Bool = true
    var newName: String?
    var result: (Result<TransferEntity, TransferErrorEntity>)? = nil
    var cancelTransferResult: (Result<Void, TransferErrorEntity>) = .failure(.generic)
    
    
    func hasExistFile(name: String, parentHandle: MEGAHandle) -> Bool {
        newName = name
        return duplicate
    }
    
    func uploadFile(withLocalPath path: String, toParent parent: MEGAHandle, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        guard let result = result else { return }
        completion(result)
    }
    
    func uploadSupportFile(atPath path: String, start: @escaping (TransferEntity) -> Void, progress: @escaping (TransferEntity) -> Void, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        guard let result = result else { return }
        completion(result)
    }
    
    func cancel(transfer: TransferEntity, completion: @escaping (Result<Void, TransferErrorEntity>) -> Void) {
        completion(cancelTransferResult)
    }
}
