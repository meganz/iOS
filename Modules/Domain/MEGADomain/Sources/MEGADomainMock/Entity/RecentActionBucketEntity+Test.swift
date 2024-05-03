import Foundation
import MEGADomain

public extension RecentActionBucketEntity {
     init(
        date: Date = Date(),
        userEmail: String? = nil,
        parentHandle: HandleEntity,
        isUpdate: Bool = true,
        isMedia: Bool = true,
        nodes: [NodeEntity] = [],
        isTesting: Bool = true
    ) {
        self.init(
            date: date,
            userEmail: userEmail,
            parentHandle: parentHandle,
            isUpdate: isUpdate,
            isMedia: isMedia,
            nodes: nodes
        )
    }
}
