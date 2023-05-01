import Foundation
import MEGADomain

public extension SetEntity {
    init(handle: HandleEntity = .invalid,
         userId: HandleEntity = .invalid,
         coverId: HandleEntity = .invalid,
         modificationTime: Date = Date(),
         name: String = "",
         changes: SetChangesEntity = [],
         isTesting: Bool = true) {
        self.init(handle: handle,
                  userId: userId,
                  coverId: coverId,
                  modificationTime: modificationTime,
                  name: name,
                  changes: changes)
    }
}
