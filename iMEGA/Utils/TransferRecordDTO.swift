
@objc class TransferRecordDTO: NSObject {
    @objc let localIdentifier: String
    @objc let parentNodeHandle: NSNumber
    
    init(localIdentifier: String, parentNodeHandle: NSNumber) {
        self.localIdentifier = localIdentifier
        self.parentNodeHandle = parentNodeHandle
        super.init()
    }
}
