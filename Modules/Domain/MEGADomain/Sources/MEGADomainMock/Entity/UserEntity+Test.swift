import Foundation
import MEGADomain

public extension UserEntity {
    init(email: String = "",
         handle: HandleEntity = .invalid,
         visibility: VisibilityEntity = .visible,
         changes: ChangeTypeEntity = .authentication,
         changeSource: ChangeSource = .externalChange,
         addedDate: Date = Date(),
         isTesting: Bool = true) {
        self.init(email: email, handle: handle, visibility: visibility, changes: changes, changeSource: changeSource, addedDate: addedDate)
    }
}
