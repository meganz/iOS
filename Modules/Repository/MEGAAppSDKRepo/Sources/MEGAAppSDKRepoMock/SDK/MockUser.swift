import MEGAAppSDKRepo
import MEGASdk

public final class MockUser: MEGAUser {
    private let _handle: MEGAHandle
    private let _visibility: MEGAUserVisibility
    private let _email: String?
    private let _changes: MEGAUserChangeType
    private let _isOwnChange: Int
    private let _addedDate: Date
    
    public init(
        handle: MEGAHandle = .invalidHandle,
        visibility: MEGAUserVisibility = .visible,
        email: String? = "",
        changes: MEGAUserChangeType = .auth,
        isOwnChange: Int = 0,
        addedDate: Date = Date()
    ) {
        self._handle = handle
        self._visibility = visibility
        self._email = email
        self._changes = changes
        self._isOwnChange = isOwnChange
        self._addedDate = addedDate
    }
    
    public override var handle: MEGAHandle {
        _handle
    }
    
    public override var visibility: MEGAUserVisibility {
        _visibility
    }
    
    public override var email: String? {
        _email
    }
    
    public override var changes: MEGAUserChangeType {
        _changes
    }
    
    public override var isOwnChange: Int {
        _isOwnChange
    }
    
    public override var timestamp: Date {
        _addedDate
    }
}
