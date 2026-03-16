import MEGAAppSDKRepo
import MEGADomain
import MEGASdk
import MEGASwift

protocol RecentActionBucketRepositoryProtocol: RepositoryProtocol, Sendable {
    func getRecentActionBuckets(excludeSensitives: Bool) async throws -> [RecentActionBucketEntity]
    func clearRecentActionBuckets(until: Date) async throws
}

struct RecentActionBucketRepository: RecentActionBucketRepositoryProtocol {
    public static var newRepo: RecentActionBucketRepository {
        RecentActionBucketRepository(sdk: MEGASdk.sharedSdk)
    }
 
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func getRecentActionBuckets(excludeSensitives: Bool) async throws -> [RecentActionBucketEntity] {
        try await withAsyncThrowingValue(in: { completion in
            sdk.getRecentActionsAsync(sinceDays: 30, maxNodes: 500, excludeSensitives: excludeSensitives, delegate: RequestDelegate { result in
                switch result {
                case .success(let request):
                    completion(.success(request.recentActionsBuckets?.compactMap { bucketEntity(from: $0) } ?? []))
                case .failure:
                    completion(.failure(GenericErrorEntity()))
                }
            })
        })
    }

    func clearRecentActionBuckets(until date: Date) async throws {
        try await withAsyncThrowingVoidValue(in: { completion in
            sdk.clearRecentActionHistory(until: Int64(date.timeIntervalSince1970), delegate: RequestDelegate { result in
                switch result {
                case .success:
                    completion(.success(()))
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
        
        let changesOwnerType: RecentActionBucketChangesOwnerType = if let user = sdk.contact(forEmail: bucket.userEmail), user.email != sdk.myEmail {
            .otherUser(user.toUserEntity())
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
