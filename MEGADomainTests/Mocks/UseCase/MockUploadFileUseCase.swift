@testable import MEGA

final class MockUploadFileUseCase: UploadFileUseCaseProtocol {
    var duplicate: Bool = true
    var newName: String?
    var result: (Result<TransferEntity, TransferErrorEntity>)? = nil
    
    
    func hasExistFile(name: String, parentHandle: MEGAHandle) -> Bool {
        newName = name
        return duplicate
    }
    
    func uploadFile(withLocalPath path: String, toParent parent: MEGAHandle, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        guard let result = result else { return }
        completion(result)
    }
}
