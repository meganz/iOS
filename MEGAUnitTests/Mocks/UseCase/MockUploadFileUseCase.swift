@testable import MEGA
import MEGADomain
import Foundation

final class MockUploadFileUseCase: UploadFileUseCaseProtocol {
    var duplicate: Bool = true
    var newName: String?
    var uploadFileResult: (Result<Void, TransferErrorEntity>)?
    var uploadSupportFileResult: (Result<TransferEntity, TransferErrorEntity>)?
    var cancelTransferResult: (Result<Void, TransferErrorEntity>) = .failure(.generic)
    var filename: String = ""
    var nodeEntity: NodeEntity?
    
    func nodeForHandle(_ handle: HandleEntity) -> NodeEntity? {
        nodeEntity
    }
    
    func hasExistFile(name: String, parentHandle: HandleEntity) -> Bool {
        newName = name
        return duplicate
    }
    
func uploadFile(_ url: URL, toParent parent: HandleEntity, fileName: String?, appData: String?, isSourceTemporary: Bool, startFirst: Bool, start: ((TransferEntity) -> Void)?, update: ((TransferEntity) -> Void)?, completion: ((Result<Void, TransferErrorEntity>) -> Void)?) {
        guard let result = uploadFileResult else { return }
        completion?(result)
    }
    
func uploadSupportFile(_ url: URL, start: @escaping (TransferEntity) -> Void, progress: @escaping (TransferEntity) -> Void, completion: @escaping (Result<TransferEntity, TransferErrorEntity>) -> Void) {
        guard let result = uploadSupportFileResult else { return }
        completion(result)
    }
    
    func cancel(transfer: TransferEntity, completion: @escaping (Result<Void, TransferErrorEntity>) -> Void) {
        completion(cancelTransferResult)
    }
    
    func tempURL(forFilename filename: String) -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(self.filename)
    }
    
    func cancelUploadTransfers() { }
}
