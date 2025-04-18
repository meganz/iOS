import MEGADomain
import MEGASdk

extension MEGARequest {
    public func toRequestEntity() -> RequestEntity {
        RequestEntity(
            nodeHandle: nodeHandle,
            type: type.toRequestTypeEntity(),
            progress: progress(),
            flag: flag,
            accountRequest: self.toAccountRequestEntity()
        )
    }
}
