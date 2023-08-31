struct AudioPlayerTrackNameUpdateCheckerViewModel {
    let configEntity: AudioPlayerConfigEntity
    let originalTrackName: String
    
    func presentableName() -> String {
        guard let nodeName = configEntity.node?.name else {
            return originalTrackName
        }
        
        let isPlayingExactNode = configEntity.node?.handle == configEntity.playerHandler.playerCurrentItem()?.node?.handle
        let isFileRenamed = nodeName != originalTrackName
        
        guard isPlayingExactNode && isFileRenamed else {
            return originalTrackName
        }
        
        return nodeName
    }
}
