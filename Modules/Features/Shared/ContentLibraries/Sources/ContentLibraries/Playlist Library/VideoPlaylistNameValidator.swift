import Foundation
import MEGADomain
import MEGAL10n
import MEGASwiftUI

@MainActor
public struct VideoPlaylistNameValidator {
    private let existingVideoPlaylistNames: @MainActor () -> [String]
    
    public init(existingVideoPlaylistNames: @MainActor @escaping () -> [String]) {
        self.existingVideoPlaylistNames = existingVideoPlaylistNames
    }
    
    enum ValidatorError: Error {
        case emptyName
    }
    
    public func validateWhenCreated(with name: String?) throws -> TextFieldAlertError? {
        guard let name = name?.trim, name.isNotEmpty else {
            throw ValidatorError.emptyName
        }
        return validate(name)
    }
    
    public func validateWhenRenamed(into name: String?) -> TextFieldAlertError? {
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
