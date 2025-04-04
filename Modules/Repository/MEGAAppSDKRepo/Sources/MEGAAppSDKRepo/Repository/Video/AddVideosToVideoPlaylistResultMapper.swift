import MEGADomain
import MEGASdk

enum AddVideosToVideoPlaylistResultMapper {
    
    static func map(request: MEGARequest?, error: MEGAError?) -> Result<Void, any Error> {
        if request == nil && error == nil {
            return .failure(VideoPlaylistErrorEntity.invalidOperation)
        } else if error != nil {
            return .failure(VideoPlaylistErrorEntity.failedToAddVideoToPlaylist)
        } else {
            return .success(())
        }
    }
}
