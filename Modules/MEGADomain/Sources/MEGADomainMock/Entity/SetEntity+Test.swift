import Foundation
import MEGADomain

public extension SetEntity {
    init(handle: HandleEntity = .invalid,
         userId: HandleEntity = .invalid,
         coverId: HandleEntity = .invalid,
         modificationTime: Date = Date(),
         name: String = "",
         isExported: Bool = false,
         changes: SetChangesEntity = [],
         isTesting: Bool = true) {
        self.init(handle: handle,
                  userId: userId,
                  coverId: coverId,
                  modificationTime: modificationTime,
                  name: name,
                  isExported: isExported,
                  changes: changes)
    }
}
