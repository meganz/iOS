import MEGASdk
import MEGAData

public final class MockRequest: MEGARequest {
    private let handle: MEGAHandle
    
    var megaSetHandle: MEGAHandle = .invalidHandle
    var megaSetElementHandle: MEGAHandle = .invalidHandle
    var megaSet: MEGASet?
    var megaSetName: String?
    var updateSet = true
    var updateSetCover = false
    var megaSetElementName: String?
    var megaElementInSet: [MEGASetElement] = []
    var megaSetElementOrder: Int64 = 0
    var megaCoverId: MEGAHandle = .invalidHandle
    var megalink: String?
    var megaSetElements: [MEGASetElement]?
    var megaFlag: Bool = false
    
    public init(handle: MEGAHandle) {
        self.handle = handle
        
        super.init()
    }
    
    public override var nodeHandle: MEGAHandle { updateSetCover ? megaCoverId : handle }
    public override var set: MEGASet? { megaSet }
    public override var text: String? { updateSet ? megaSetName : megaSetElementName }
    public override var parentHandle: UInt64 { updateSet ? megaSetHandle : megaSetElementHandle }
    public override var elementsInSet: [MEGASetElement] { megaElementInSet }
    public override var number: NSNumber { NSNumber(value: megaSetElementOrder) }
    public override var link: String? { megalink }
    public override var flag: Bool { megaFlag }
}
