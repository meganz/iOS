import MEGAAppSDKRepo
import MEGASdk

public final class MockTransfer: MEGATransfer, @unchecked Sendable {
    private let _type: MEGATransferType
    private let _nodeHandle: UInt64
    private let _parentHandle: UInt64
    private let _startPos: Int64
    private let _endPos: Int64
    private let _deltaSize: Int64
    private let _lastErrorExtended: MEGAError
    private let _isStreamingTransfer: Bool
    private let _parentPath: String?
    private let _fileName: String?
    private let _isFolderTransfer: Bool
    private let _stage: MEGATransferStage
    private let _state: MEGATransferState
    
    public init(type: MEGATransferType = .download,
                nodeHandle: UInt64 = 0,
                parentHandle: UInt64 = 0,
                startPos: Int64 = 0,
                endPos: Int64 = 0,
                deltaSize: Int64 = 0,
                lastErrorExtended: MEGAError = MEGAError(),
                isStreamingTransfer: Bool = false,
                parentPath: String? = nil,
                fileName: String? = nil,
                isFolderTransfer: Bool = false,
                stage: MEGATransferStage = .none,
                state: MEGATransferState = .none) {
        self._type = type
        self._nodeHandle = nodeHandle
        self._parentHandle = parentHandle
        self._startPos = startPos
        self._endPos = endPos
        self._deltaSize = deltaSize
        self._lastErrorExtended = lastErrorExtended
        self._isStreamingTransfer = isStreamingTransfer
        self._parentPath = parentPath
        self._fileName = fileName
        self._isFolderTransfer = isFolderTransfer
        self._stage = stage
        self._state = state
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
    
    public override var parentPath: String? {
        _parentPath
    }
    
    public override var isStreamingTransfer: Bool {
        _isStreamingTransfer
    }
    
    public override var fileName: String? {
        _fileName
    }
    
    public override var isFolderTransfer: Bool {
        _isFolderTransfer
    }
    
    public override var stage: MEGATransferStage {
        _stage
    }
    
    public override var state: MEGATransferState {
        _state
    }
}
