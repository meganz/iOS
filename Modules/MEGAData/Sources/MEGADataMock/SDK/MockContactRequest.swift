import MEGASdk
import MEGAData

public final class MockContactRequest: MEGAContactRequest {
    private let _handle: MEGAHandle
    private let _sourceEmail: String
    private let _sourceMessage: String
    private let _targetEmail: String
    private let _creationTime: Date
    private let _modificationTime: Date
    
    public init(
        handle: MEGAHandle = .invalidHandle,
        sourceEmail: String = "",
        sourceMessage: String = "",
        targetEmail: String = "",
        creationTime: Date = Date(),
        modificationTime: Date = Date()
    ) {
        self._handle = handle
        self._sourceEmail = sourceEmail
        self._sourceMessage = sourceMessage
        self._targetEmail = targetEmail
        self._creationTime = creationTime
        self._modificationTime = modificationTime
    }
    
    public override var handle: MEGAHandle { _handle }
    public override var sourceEmail: String { _sourceEmail }
    public override var sourceMessage: String { _sourceMessage }
    public override var targetEmail: String { _targetEmail }
    public override var creationTime: Date { _creationTime }
    public override var modificationTime: Date { _modificationTime }
}
