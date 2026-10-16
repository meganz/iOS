import ContentLibraries
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct CreateAlbumAlertInput {
    let albumNames: [String]
}

extension View {
    @MainActor
    func createAlbumAlert(
        request: Binding<CreateAlbumAlertInput?>,
        create: @MainActor @escaping (String) -> Void
    ) -> some View {
        alert(
            isPresented: Binding(
                get: { request.wrappedValue != nil },
                set: { if !$0 { request.wrappedValue = nil } }
            ),
            .createAlbum(albumNames: request.wrappedValue?.albumNames ?? [], create: create)
        )
    }
}

extension TextFieldAlertViewModel {
    static func createAlbum(albumNames: [String], create: @MainActor @escaping (String) -> Void) -> Self {
        Self(
            title: Strings.Localizable.CameraUploads.Albums.Create.Alert.title,
            placeholderText: albumNames.newAlbumName(),
            affirmativeButtonTitle: Strings.Localizable.createFolderButton,
            destructiveButtonTitle: Strings.Localizable.cancel,
            action: { name in
                guard let name else { return }
                create(name.isEmpty ? albumNames.newAlbumName() : name)
            },
            validator: AlbumNameValidator { albumNames }.create
        )
    }
}
