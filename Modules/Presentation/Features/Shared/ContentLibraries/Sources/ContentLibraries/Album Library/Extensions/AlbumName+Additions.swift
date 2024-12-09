import MEGAL10n

public typealias AlbumName = String

public extension [AlbumName] {
    func newAlbumName() -> String {
        let placeholderName = Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder
        let prefixedNames = Set(self.filter { $0.hasPrefix(placeholderName) })
        
        guard prefixedNames.count > 0,
              prefixedNames.contains(placeholderName) else {
            return placeholderName
        }
        
        for i in 1...prefixedNames.count {
            let newName = "\(placeholderName) (\(i))"
            if !prefixedNames.contains(newName) {
                return newName
            }
        }
        return placeholderName
    }
}
