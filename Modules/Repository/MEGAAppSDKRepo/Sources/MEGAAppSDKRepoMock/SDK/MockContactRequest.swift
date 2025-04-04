import MEGAAppSDKRepo
import MEGASdk

public final class MockContactRequest: MEGAContactRequest {
    private let _handle: MEGAHandle
    private let _sourceEmail: String
    private let _sourceMessage: String
    private let _targetEmail: String
    private let _creationTime: Date
    private let _modificationTime: Date
    private let _isOutgoing: Bool
    private let _status: MEGAContactRequestStatus
    
    public init(
        handle: MEGAHandle = .invalidHandle,
        sourceEmail: String = "",
        sourceMessage: String = "",
        targetEmail: String = "",
        creationTime: Date = Date(),
        modificationTime: Date = Date(),
        isOutgoing: Bool = false,
        status: MEGAContactRequestStatus = .unresolved
    ) {
        self._handle = handle
        self._sourceEmail = sourceEmail
        self._sourceMessage = sourceMessage
        self._targetEmail = targetEmail
        self._creationTime = creationTime
        self._modificationTime = modificationTime
        self._isOutgoing = isOutgoing
        self._status = status
    }
    
    public override var handle: MEGAHandle { _handle }
    public override var sourceEmail: String { _sourceEmail }
    public override var sourceMessage: String { _sourceMessage }
    public override var targetEmail: String { _targetEmail }
    public override var creationTime: Date { _creationTime }
    public override var modificationTime: Date { _modificationTime }
    public override func isOutgoing() -> Bool { _isOutgoing }
    public override var status: MEGAContactRequestStatus { _status }
}
