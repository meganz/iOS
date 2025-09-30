import Foundation
import MEGADomain

public struct MockTransferInventoryUseCase: TransferInventoryUseCaseProtocol {
    private let transfers: [TransferEntity]
    private let downloadTransfers: [TransferEntity]
    private let uploadTransfers: [TransferEntity]
    private let completedTransfers: [TransferEntity]
    private let defaultDocumentsDirectory: String
    
    public init(
        transfers: [TransferEntity] = [],
        downloadTransfers: [TransferEntity] = [],
        uploadTransfers: [TransferEntity] = [],
        completedTransfers: [TransferEntity] = [],
        defaultDocumentsDirectory: String = "/mock/documents/directory"
    ) {
        self.transfers = transfers
        self.downloadTransfers = downloadTransfers
        self.uploadTransfers = uploadTransfers
        self.completedTransfers = completedTransfers
        self.defaultDocumentsDirectory = defaultDocumentsDirectory
    }
    
    public func transfers(filteringUserTransfers: Bool) -> [TransferEntity] {
        transfers
    }
    
    public func transfers(filteringUserTransfers: Bool) async -> [TransferEntity] {
        transfers
    }
    
    public func downloadTransfers(filteringUserTransfers: Bool) -> [TransferEntity] {
        downloadTransfers
    }
    
    public func uploadTransfers(filteringUserTransfers: Bool) -> [TransferEntity] {
        uploadTransfers
    }
    
    public func completedTransfers(filteringUserTransfers: Bool) -> [TransferEntity] {
        completedTransfers
    }
    
    public func documentsDirectory() -> URL {
        URL(fileURLWithPath: defaultDocumentsDirectory)
    }
    
    public func areThereAnyTransferWithAppData(matching filter: @escaping (String) -> Bool) -> Bool {
        let allTransfers = transfers(filteringUserTransfers: false)
        return allTransfers.compactMap(\.appData).contains(where: filter)
    }
}
