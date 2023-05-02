import Foundation
import MEGADomain

public extension SetElementEntity {
    init(handle: HandleEntity = .invalid,
         ownerId: HandleEntity = .invalid,
         order: HandleEntity = .invalid,
         nodeId: HandleEntity = .invalid,
         modificationTime: Date = Date(),
         name: String = "",
         changes: SetElementChangesEntity = [],
         isTesting: Bool = true) {
        self.init(handle: handle,
                  ownerId: ownerId,
                  order: order,
                  nodeId: nodeId,
                  modificationTime: modificationTime,
                  name: name,
                  changes: changes)
    }
}
