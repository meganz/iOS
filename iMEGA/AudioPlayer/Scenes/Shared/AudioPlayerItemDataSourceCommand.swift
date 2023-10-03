import MEGASdk

final class AudioPlayerItemDataSourceCommand {
    private var configEntity: AudioPlayerConfigEntity
    
    init(configEntity: AudioPlayerConfigEntity) {
        self.configEntity = configEntity
    }
    
    func executeRefreshItemDataSource(with updatedNode: MEGANode) {
        configEntity.node = updatedNode
        
        refreshItemDataSourceTracks(with: updatedNode)
    }
    
    private func refreshItemDataSourceTracks(with updatedNode: MEGANode) {
        let tracks = configEntity.playerHandler.currentPlayer()?.tracks ?? []
        let updatedTracks = updateTracks(with: updatedNode, tracks: tracks)
        configEntity.playerHandler.currentPlayer()?.tracks = updatedTracks
    }
    
    private func updateTracks(with updatedNode: MEGANode, tracks: [AudioPlayerItem]) -> [AudioPlayerItem] {
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
