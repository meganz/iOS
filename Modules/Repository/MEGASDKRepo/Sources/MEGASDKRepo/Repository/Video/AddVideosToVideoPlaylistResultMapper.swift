import MEGADomain
import MEGASdk

struct AddVideosToVideoPlaylistResultMapper {
    
    private init() {}
    
    static func map(request: MEGARequest?, error: MEGAError?) ->  Result<SetEntity, any Error>? {
        guard let error else {
            return nil
        }
        
        guard error.type == .apiOk else {
            return .failure(VideoPlaylistErrorEntity.failedToAddVideoToPlaylist)
        }
        
        guard let setEntity = request?.set?.toSetEntity() else {
            return .failure(GenericErrorEntity())
        }
        return .success(setEntity)
        
    }
}
