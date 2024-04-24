import MEGADomain
import MEGASdk

struct DeleteVideoPlaylistElementsMapper {
    
    private init() {}
    
    static func map(request: MEGARequest?, error: MEGAError?) -> Result<SetEntity, any Error> {
        guard let error else {
            return .failure(VideoPlaylistErrorEntity.invalidOperation)
        }
        
        guard error.type == .apiOk else {
            return .failure(VideoPlaylistErrorEntity.failedToDeleteVideoPlaylistElements)
        }
        
        guard let setEntity = request?.set?.toSetEntity() else {
            return .failure(VideoPlaylistErrorEntity.failedToRetrieveSetFromRequest)
        }
        
        return .success(setEntity)
    }
}
