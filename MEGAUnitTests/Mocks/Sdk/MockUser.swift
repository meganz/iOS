import Foundation
@testable import MEGA
import MEGADomain

final class MockUser: MEGAUser {
    private let _handle: HandleEntity
    private let _visibility: MEGAUserVisibility
    private let _email: String
    private let _changes: MEGAUserChangeType
    private let _isOwnChange: Int
    private let _addedDate: Date
    
    init(handle: HandleEntity = .invalid,
         visibility: MEGAUserVisibility = .visible,
         email: String = "",
         changes: MEGAUserChangeType = .auth,
         isOwnChange: Int = 0,
         addedDate: Date = Date()) {
        self._handle = handle
        self._visibility = visibility
        self._email = email
        self._changes = changes
        self._isOwnChange = isOwnChange
        self._addedDate = addedDate
    }
    
    override var handle: HandleEntity {
        _handle
    }
    
    override var visibility: MEGAUserVisibility {
        _visibility
    }
    
    override var email: String {
        _email
    }
    
    override var changes: MEGAUserChangeType {
        _changes
    }
    
    override var isOwnChange: Int {
        _isOwnChange
    }
    
    override var timestamp: Date {
        _addedDate
    }
}
