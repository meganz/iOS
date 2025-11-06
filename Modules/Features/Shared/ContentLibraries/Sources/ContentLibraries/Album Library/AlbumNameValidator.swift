import Foundation
import MEGADomain
import MEGAL10n
import MEGASwiftUI

@MainActor
public struct AlbumNameValidator {
    private let existingAlbumNames: @MainActor () -> [String]
    
    public init(existingAlbumNames: @MainActor @escaping () -> [String]) {
        self.existingAlbumNames = existingAlbumNames
    }
    
    public func create(_ name: String?) -> TextFieldAlertError? {
        guard let name = name, name.isNotEmpty else { return nil }
       
        return validate(name)
    }
    
    public func rename(_ name: String?) -> TextFieldAlertError? {
        guard let name = name, name.isNotEmpty else {
            return TextFieldAlertError(title: "", description: "")
        }
        
        return validate(name)
    }
    
    private func validate(_ name: String) -> TextFieldAlertError? {
        guard let name = name.trim, name.isNotEmpty else {
            return TextFieldAlertError(title: "", description: "")
        }
        
        if name.containsInvalidFileFolderNameCharacters {
            return TextFieldAlertError(title: Strings.Localizable.General.Error.charactersNotAllowed(String.Constants.invalidFileFolderNameCharactersToDisplay), description: Strings.Localizable.CameraUploads.Albums.Create.Alert.enterNewName)
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
        return reservedNames.contains(where: { name.caseInsensitiveCompare($0) == .orderedSame })
    }
}
