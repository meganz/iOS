import Foundation
import MEGADomain

struct ShareEntity {
    let sharedUserEmail: String?
    let nodeHandle: HandleEntity
    let accessLevel: ShareAccessLevelEntity
    let createdDate: Date
    let isPending: Bool
}
