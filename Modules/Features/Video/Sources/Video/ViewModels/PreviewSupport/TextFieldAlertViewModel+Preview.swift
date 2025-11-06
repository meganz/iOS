import MEGAL10n
import MEGASwiftUI

extension TextFieldAlertViewModel {
    
    static let preview = TextFieldAlertViewModel(
        textString: "playlist name",
        title: Strings.Localizable.Videos.Tab.Playlist.Content.Alert.title,
        placeholderText: Strings.Localizable.Videos.Tab.Playlist.Content.Alert.placeholder,
        affirmativeButtonTitle: Strings.Localizable.Videos.Tab.Playlist.Content.Alert.Button.create,
        affirmativeButtonInitiallyEnabled: false,
        destructiveButtonTitle: Strings.Localizable.cancel,
        highlightInitialText: true
    )
}
