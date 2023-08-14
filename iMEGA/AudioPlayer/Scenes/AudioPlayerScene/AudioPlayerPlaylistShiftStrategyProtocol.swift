protocol AudioPlayerPlaylistShiftStrategyProtocol {
    func shift(tracks: [AudioPlayerItem], startItem: AudioPlayerItem) -> [AudioPlayerItem]
}

struct AudioPlayerDefaultPlaylistShiftStrategy: AudioPlayerPlaylistShiftStrategyProtocol {
    
    func shift(tracks: [AudioPlayerItem], startItem: AudioPlayerItem) -> [AudioPlayerItem] {
        guard tracks.contains(startItem) else { return tracks }
        return tracks.shifted(tracks.firstIndex(of: startItem) ?? 0)
    }
}

struct AudioPlayerAllAudioAsPlaylistShiftStrategy: AudioPlayerPlaylistShiftStrategyProtocol {
    
    func shift(tracks: [AudioPlayerItem], startItem: AudioPlayerItem) -> [AudioPlayerItem] {
        if tracks.isEmpty {
            return []
        }
        
        guard containsStartItemInTracksByLastPathComponent(tracks: tracks, startItem: startItem) else {
            return tracks
        }
        
        guard let startItemIndex = findIndexByLastPathComponent(of: startItem, in: tracks) else {
            return tracks
        }
        
        var mutableTracks = tracks
        return mutableTracks.shifted(startItemIndex)
    }
    
    private func containsStartItemInTracksByLastPathComponent(tracks: [AudioPlayerItem], startItem: AudioPlayerItem) -> Bool {
        tracks.contains { $0.url.lastPathComponent == startItem.url.lastPathComponent }
    }
    
    private func findIndexByLastPathComponent(of startItem: AudioPlayerItem, in tracks: [AudioPlayerItem]) -> Int? {
        for (index, track) in tracks.enumerated() where track.url.lastPathComponent == startItem.url.lastPathComponent {
            return index
        }
        return nil
    }
    
}
