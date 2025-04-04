import MEGADomain
import MEGASdk

enum DeleteVideoPlaylistElementsMapper {
    
    static func map(request: MEGARequest?, error: MEGAError?) -> Result<Void, any Error> {
        if request == nil && error == nil {
            .failure(VideoPlaylistErrorEntity.invalidOperation)
        } else if error != nil {
            .failure(VideoPlaylistErrorEntity.failedToDeleteVideoPlaylistElements)
        } else {
           .success(())
        }
    }
}
