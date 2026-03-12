import Foundation
import MEGADomain

enum RecentActionBucketType: Sendable {
    case singleFile(NodeEntity)
    case singleMedia(NodeEntity)
    case multipleMedia([NodeEntity])
    case mixedFiles([NodeEntity])
}

enum RecentActionBucketChangesOwnerType: Sendable {
    case currentUser
    case otherUser(_ email: String)
}

enum RecentActionBucketShareOriginType: Sendable {
    case inShare
    case outShare
    case none
}

enum RecentActionBucketChangesType: Sendable {
    case newFiles
    case updatedFiles
}

struct RecentActionBucketEntity: Identifiable {
    let id = UUID()
    let date: Date
    let parent: NodeEntity?
    let type: RecentActionBucketType
    let changesType: RecentActionBucketChangesType
    let changesOwnerType: RecentActionBucketChangesOwnerType
    let shareOriginType: RecentActionBucketShareOriginType
}
