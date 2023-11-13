import MEGASdk
import MEGASDKRepo

public final class MockTransfer: MEGATransfer {
    private let _type: MEGATransferType
    private let _nodeHandle: UInt64
    private let _parentHandle: UInt64
    private let _startPos: Int64
    private let _endPos: Int64
    private let _deltaSize: Int64
    private let _lastErrorExtended: MEGAError
    
    public init(type: MEGATransferType = .download,
                nodeHandle: UInt64 = 0,
                parentHandle: UInt64 = 0,
                startPos: Int64 = 0,
                endPos: Int64 = 0,
                deltaSize: Int64 = 0,
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
    
    public override var startPos: Int64 {
        _startPos
    }
    
    public override var endPos: Int64 {
        _endPos
    }
    
    public override var deltaSize: Int64 {
        _deltaSize
    }
    
    public override var lastErrorExtended: MEGAError {
        _lastErrorExtended
    }
}
