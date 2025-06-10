import Combine
import MEGAAssets
import SwiftUI

@MainActor
final class MyAvatarIconViewModel<AvatarObserver: MyAvatarObserver>: ObservableObject {
    @Published var avatar: UIImage = MEGAAssets.UIImage.iconContacts
    @Published var text: String?

    private var avatarObserver: AvatarObserver
    private let onAvatarTapped: () -> Void

    init(
        avatarObserver: AvatarObserver,
        onAvatarTapped: @escaping () -> Void
    ) {
        self.avatarObserver = avatarObserver
        self.onAvatarTapped = onAvatarTapped

        self.avatarObserver.notifyUpdate = { [weak self] output in
            self?.avatar = output.avatarImage
            self?.text = output.notificationNumber
        }

        avatarObserver.viewIsReady()
    }

    func onAppear() {
        avatarObserver.viewIsAppearing()
    }

    func openUserProfile() {
        onAvatarTapped()
    }
}
