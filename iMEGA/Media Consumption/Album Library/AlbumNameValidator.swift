import Foundation
import MEGADomain

struct AlbumNameValidator {
    let albumTitle: String
    let existingAlbumNames: () -> [String]
    
    func create(_ name: String?) -> TextFieldAlertError? {
        guard let name = name, name.isNotEmpty else { return nil }
       
        return validate(name)
    }
    
    func rename(_ name: String?) -> TextFieldAlertError? {
        guard let name = name, name.isNotEmpty else {
            return TextFieldAlertError(title: "", description: "")
        }
        
        return validate(name)
    }
    
    private func validate(_ name: String) -> TextFieldAlertError? {
        guard let name = name.trim, name.isNotEmpty else {
            return TextFieldAlertError(title: "", description: "")
        }
        
        if name.mnz_containsInvalidChars() {
            return TextFieldAlertError(title: Strings.Localizable.General.Error.charactersNotAllowed(String.Constants.invalidFileFolderNameCharacters), description: Strings.Localizable.CameraUploads.Albums.Create.Alert.enterNewName)
        }
        if isReservedAlbumName(name: name) {
            return TextFieldAlertError(title: Strings.Localizable.CameraUploads.Albums.Create.Alert.albumNameNotAllowed, description: Strings.Localizable.CameraUploads.Albums.Create.Alert.enterDifferentName)
        }
        if existingAlbumNames().first(where: { $0 == name }) != nil {
            return TextFieldAlertError(title: Strings.Localizable.CameraUploads.Albums.Create.Alert.userAlbumExists, description: Strings.Localizable.CameraUploads.Albums.Create.Alert.enterDifferentName)
        }
        return nil
    }
    
    private func isReservedAlbumName(name: String) -> Bool {
        let reservedNames = [Strings.Localizable.CameraUploads.Albums.Favourites.title,
                             Strings.Localizable.CameraUploads.Albums.Gif.title,
                             Strings.Localizable.CameraUploads.Albums.Raw.title,
                             Strings.Localizable.CameraUploads.Albums.MyAlbum.title,
                             Strings.Localizable.CameraUploads.Albums.SharedAlbum.title]
        return reservedNames.reduce(false) { $0 || name.caseInsensitiveCompare($1) == .orderedSame }
    }
}
