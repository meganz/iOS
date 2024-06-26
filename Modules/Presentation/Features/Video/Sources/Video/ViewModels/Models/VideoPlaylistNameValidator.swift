import Foundation
import MEGADomain
import MEGAL10n
import MEGASwiftUI

struct VideoPlaylistNameValidator {
    let existingVideoPlaylistNames: () -> [String]
    
    enum ValidatorError: Error {
        case emptyName
    }
    
    func validateWhenCreated(with name: String?) throws -> TextFieldAlertError? {
        guard let name = name?.trim, name.isNotEmpty else {
            throw ValidatorError.emptyName
        }
        return validate(name)
    }
    
    func validateWhenRenamed(into name: String?) -> TextFieldAlertError? {
        guard let name = name?.trim, name.isNotEmpty else {
            return TextFieldAlertError(title: "", description: "")
        }
        return validate(name)
    }
    
    private func validate(_ name: String) -> TextFieldAlertError? {
        if name.containsInvalidFileFolderNameCharacters {
            return TextFieldAlertError(
                title: Strings.Localizable.General.Error.charactersNotAllowed(String.Constants.invalidFileFolderNameCharactersToDisplay),
                description: Strings.Localizable.Videos.Tab.Playlist.Create.Alert.enterNewName
            )
        }
        if isReservedVideoPlaylistName(name: name) {
            return TextFieldAlertError(
                title: Strings.Localizable.Videos.Tab.Playlist.Create.Alert.videoPlaylistNameNotAllowed,
                description: Strings.Localizable.Videos.Tab.Playlist.Create.Alert.enterDifferentName
            )
        }
        if existingVideoPlaylistNames().first(where: { $0 == name }) != nil {
            return TextFieldAlertError(
                title: Strings.Localizable.Videos.Tab.Playlist.Create.Alert.userVideoPlaylistExists,
                description: Strings.Localizable.Videos.Tab.Playlist.Create.Alert.enterDifferentName
            )
        }
        return nil
    }
    
    private func isReservedVideoPlaylistName(name: String) -> Bool {
        let reservedNames = [
            Strings.Localizable.Videos.Tab.Playlist.Content.PlaylistCell.Title.favorites
        ]
        return reservedNames.contains(where: { name.caseInsensitiveCompare($0) == .orderedSame })
    }
}
