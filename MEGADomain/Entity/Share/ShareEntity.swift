import Foundation

struct ShareEntity {
    let sharedUserEmail: String?
    let nodeHandle: MEGAHandle
    let accessLevel: ShareAccessLevelEntity
    let createdDate: Date
    let isPending: Bool
}
