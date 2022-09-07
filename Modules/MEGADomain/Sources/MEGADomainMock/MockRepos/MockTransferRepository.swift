import MEGADomain

public struct MockTransferRepository: TransfersRepositoryProtocol {
    public static var newRepo: MockTransferRepository {
        MockTransferRepository()
    }

    public func transfers() -> [TransferEntity] {
        [TransferEntity(type: .download, path: "/Documents"), TransferEntity(type: .upload, path: "uploads"), TransferEntity(type: .download, path: "tmp")]
    }
    
    public func downloadTransfers() -> [TransferEntity] {
        [TransferEntity(type: .download, path: "/Documents"), TransferEntity(type: .download, path: "tmp")]
    }
    
    public func uploadTransfers() -> [TransferEntity] {
        [TransferEntity(type: .upload, path: "uploads"), TransferEntity(type: .upload, path: "tmp")]
    }
    
    public func completedTransfers() -> [TransferEntity] {
        [TransferEntity(type: .upload, path: "uploads"), TransferEntity(type: .upload, path: "tmp"),
         TransferEntity(type: .download, path: "/Documents"), TransferEntity(type: .download, path: "tmp")]
    }
}
