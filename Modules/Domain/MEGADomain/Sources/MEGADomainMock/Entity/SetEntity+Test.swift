import Foundation
import MEGADomain

public extension SetEntity {
    init(handle: HandleEntity = .invalid,
         userId: HandleEntity = .invalid,
         coverId: HandleEntity = .invalid,
         creationTime: Date = Date(),
         modificationTime: Date = Date(),
         setType: SetTypeEntity = .invalid,
         name: String = "",
         isExported: Bool = false,
         changeTypes: SetChangeTypeEntity = [],
         isTesting: Bool = true) {
        self.init(handle: handle,
                  userId: userId,
                  coverId: coverId,
                  creationTime: creationTime,
                  modificationTime: modificationTime,
                  setType: setType,
                  name: name,
                  isExported: isExported,
                  changeTypes: changeTypes)
    }
}
