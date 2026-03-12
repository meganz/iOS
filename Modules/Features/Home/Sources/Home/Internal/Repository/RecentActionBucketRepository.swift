import MEGAAppSDKRepo
import MEGADomain
import MEGASdk
import MEGASwift

protocol RecentActionBucketRepositoryProtocol: RepositoryProtocol, Sendable {
    func getRecentActionBuckets() async throws -> [RecentActionBucketEntity]
}

struct RecentActionBucketRepository: RecentActionBucketRepositoryProtocol {
    public static var newRepo: RecentActionBucketRepository {
        RecentActionBucketRepository(sdk: MEGASdk.sharedSdk)
    }
 
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func getRecentActionBuckets() async throws -> [RecentActionBucketEntity] {
        try await withAsyncThrowingValue(in: { completion in
            sdk.getRecentActionsAsync(sinceDays: 30, maxNodes: 500, excludeSensitives: false, delegate: RequestDelegate { result in
                switch result {
                case .success(let request):
                    completion(.success(request.recentActionsBuckets?.compactMap { bucketEntity(from: $0) } ?? []))
                case .failure:
                    completion(.failure(GenericErrorEntity()))
                }
            })
        })
    }
    
    private func bucketEntity(from bucket: MEGARecentActionBucket) -> RecentActionBucketEntity? {
        guard let nodes = bucket.nodesList?.toNodeEntities(), let node = nodes.first else { return nil }
        let bucketType: RecentActionBucketType = if nodes.count == 1 {
            if bucket.isMedia {
                .singleMedia(node)
            } else {
                .singleFile(node)
            }
        } else {
            if bucket.isMedia {
                .multipleMedia(nodes)
            } else {
                .mixedFiles(nodes)
            }
        }
        
        let changesOwnerType: RecentActionBucketChangesOwnerType = if let userEmail = bucket.userEmail, userEmail != sdk.myEmail {
            .otherUser(userEmail)
        } else {
            .currentUser
        }
        
        return RecentActionBucketEntity(
            date: bucket.timestamp ?? Date(),
            parent: sdk.node(forHandle: bucket.parentHandle)?.toNodeEntity(),
            type: bucketType,
            changesType: changesType(of: bucket),
            changesOwnerType: changesOwnerType,
            shareOriginType: shareOriginType(of: bucket)
        )
    }
    
    private func shareOriginType(of bucket: MEGARecentActionBucket) -> RecentActionBucketShareOriginType {
        var parent = sdk.node(forHandle: bucket.parentHandle)
        while let node = parent {
            if node.isInShare() {
                return .inShare
            } else if node.isOutShare() {
                return .outShare
            } else {
                parent = sdk.node(forHandle: node.parentHandle)
            }
        }
        return .none
    }
    
    private func changesType(of bucket: MEGARecentActionBucket) -> RecentActionBucketChangesType {
        if bucket.isUpdate {
            .updatedFiles
        } else {
            .newFiles
        }
    }
}
