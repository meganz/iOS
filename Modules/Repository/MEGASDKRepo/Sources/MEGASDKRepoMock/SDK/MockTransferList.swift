import MEGASdk

public final class MockTransferList: MEGATransferList {
    private let transfers: [MEGATransfer]
    
    public init(transfers: [MEGATransfer] = []) {
        self.transfers = transfers
        super.init()
    }
    
    public override var size: Int {
        transfers.count
    }
    
    public override func transfer(at index: Int) -> MEGATransfer? {
        transfers[safe: index]
    }
}
