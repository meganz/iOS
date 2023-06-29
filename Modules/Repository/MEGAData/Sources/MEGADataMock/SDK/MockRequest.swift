import MEGAData
import MEGASdk

public final class MockRequest: MEGARequest {
    private let handle: MEGAHandle
    private let _set: MEGASet?
    private let _text: String?
    private let _parentHandle: UInt64
    private let _elementsInSet: [MEGASetElement]
    private let _number: NSNumber
    private let _link: String?
    private let _flag: Bool
    private let _publicNode: MEGANode?
    
    public init(handle: MEGAHandle,
                set: MEGASet? = nil,
                text: String? = nil,
                parentHandle: MEGAHandle = .invalidHandle,
                elementInSet: [MEGASetElement] = [],
                number: NSNumber = 0,
                link: String? = nil,
                flag: Bool = false,
                publicNode: MEGANode? = nil) {
        self.handle = handle
        _set = set
        _text = text
        _parentHandle = parentHandle
        _elementsInSet = elementInSet
        _number = number
        _link = link
        _flag = flag
        _publicNode = publicNode
        super.init()
    }
    
    public override var nodeHandle: MEGAHandle { handle }
    public override var set: MEGASet? { _set }
    public override var text: String? { _text }
    public override var parentHandle: UInt64 { _parentHandle }
    public override var elementsInSet: [MEGASetElement] { _elementsInSet }
    public override var number: NSNumber { _number }
    public override var link: String? { _link }
    public override var flag: Bool { _flag }
    public override var publicNode: MEGANode? { _publicNode }
}
