struct AudioPlayerTrackUpdaterViewModel {
    
    static func updateTracks(with updatedNode: MEGANode, tracks: [AudioPlayerItem]) -> [AudioPlayerItem] {
        var newTracks = tracks
        
        guard
            let (trackToUpdateIndex, trackToUpdate) = tracks.enumerated().first(where: { $0.element.node?.handle == updatedNode.handle })
        else {
            return tracks
        }
        
        trackToUpdate.name = updatedNode.name ?? trackToUpdate.name
        newTracks[trackToUpdateIndex] = trackToUpdate
        
        return newTracks
    }
}
