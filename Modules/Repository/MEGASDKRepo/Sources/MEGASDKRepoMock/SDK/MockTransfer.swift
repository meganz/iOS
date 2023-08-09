import MEGASdk
import MEGASDKRepo

public final class MockTransfer: MEGATransfer {
    private let _type: MEGATransferType
    private let _nodeHandle: UInt64
    private let _parentHandle: UInt64
    private let _startPos: NSNumber
    private let _endPos: NSNumber
    private let _deltaSize: NSNumber
    private let _lastErrorExtended: MEGAError
    
    public init(type: MEGATransferType = .download,
                nodeHandle: UInt64 = 0,
                parentHandle: UInt64 = 0,
                startPos: NSNumber = 0,
                endPos: NSNumber = 0,
                deltaSize: NSNumber = 0,
                lastErrorExtended: MEGAError = MEGAError()) {
        self._type = type
        self._nodeHandle = nodeHandle
        self._parentHandle = parentHandle
        self._startPos = startPos
        self._endPos = endPos
        self._deltaSize = deltaSize
        self._lastErrorExtended = lastErrorExtended
    }
    
    public override var type: MEGATransferType {
        _type
    }
    
    public override var nodeHandle: UInt64 {
        _nodeHandle
    }
    
    public override var parentHandle: UInt64 {
        _parentHandle
    }
    
    public override var startPos: NSNumber {
        _startPos
    }
    
    public override var endPos: NSNumber {
        _endPos
    }
    
    public override var deltaSize: NSNumber {
        _deltaSize
    }
    
    public override var lastErrorExtended: MEGAError {
        _lastErrorExtended
    }
}
