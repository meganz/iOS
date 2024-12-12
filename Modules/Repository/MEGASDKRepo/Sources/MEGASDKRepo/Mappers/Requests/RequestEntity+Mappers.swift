import MEGADomain
import MEGASdk

extension MEGARequest {
    public func toRequestEntity() -> RequestEntity {
        RequestEntity(
            type: type.toRequestTypeEntity(),
            progress: progress()
        )
    }
}
