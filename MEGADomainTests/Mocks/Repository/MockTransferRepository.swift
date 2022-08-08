@testable import MEGA
import MEGADomain

struct MockTransferRepository: TransfersRepositoryProtocol {
    func transfers() -> [TransferEntity] {
        [TransferEntity(type: .download, path: "/Documents"), TransferEntity(type: .upload, path: "uploads"), TransferEntity(type: .download, path: "tmp")]
    }
    
    func downloadTransfers() -> [TransferEntity] {
        [TransferEntity(type: .download, path: "/Documents"), TransferEntity(type: .download, path: "tmp")]
    }
    
    func uploadTransfers() -> [TransferEntity] {
        [TransferEntity(type: .upload, path: "uploads"), TransferEntity(type: .upload, path: "tmp")]
    }
    
    func completedTransfers() -> [TransferEntity] {
        [TransferEntity(type: .upload, path: "uploads"), TransferEntity(type: .upload, path: "tmp"),
         TransferEntity(type: .download, path: "/Documents"), TransferEntity(type: .download, path: "tmp")]
    }
}
