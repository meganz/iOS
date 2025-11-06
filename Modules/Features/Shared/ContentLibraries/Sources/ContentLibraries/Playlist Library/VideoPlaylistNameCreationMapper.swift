import MEGAL10n

public enum VideoPlaylistNameCreationMapper {
    
    public static func videoPlaylistName(from newName: String?, from source: [String]) -> String {
        let baseName = baseName(from: newName)
        
        if source.notContains(baseName) {
            return baseName
        }

        for index in 1...(source.count + 1) {
            let potentialNewName = "\(baseName) (\(index))"
            if source.notContains(potentialNewName) {
                return potentialNewName
            }
        }
        
        return baseName
    }
    
    private static func baseName(from newName: String?) -> String {
        if let newName, newName.isNotEmpty {
            newName
        } else {
            Strings.Localizable.Videos.Tab.Playlist.Content.Alert.placeholder
        }
    }
}
