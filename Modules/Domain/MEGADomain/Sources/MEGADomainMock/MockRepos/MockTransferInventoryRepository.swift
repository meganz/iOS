import MEGADomain

public struct MockTransferInventoryRepository: TransferInventoryRepositoryProtocol {
    
    public static var newRepo: MockTransferInventoryRepository {
        MockTransferInventoryRepository()
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
    
    public func isExportFileTransfer(_ transfer: TransferEntity) -> Bool {
        transfer.appData?.contains(">exportFile") ?? false
    }
    
    public func isSaveToPhotosAppTransfer(_ transfer: TransferEntity) -> Bool {
        transfer.appData?.contains(">SaveInPhotosApp") ?? false
    }
    
    public func areThereAnyTransferWithAppData(matching filter: @escaping (String) -> Bool) -> Bool {
        let allTransfers = transfers()
        return allTransfers.compactMap(\.appData).contains(where: filter)
    }
}
