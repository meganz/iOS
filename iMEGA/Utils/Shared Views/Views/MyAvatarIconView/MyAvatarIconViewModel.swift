import Combine
import SwiftUI

@MainActor
final class MyAvatarIconViewModel<AvatarObserver: MyAvatarObserver>: ObservableObject {
    @Published var avatar: UIImage?
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
            guard let self else { return }
            let resizedImage = output.avatarImage

            asyncOnMain {
                self.avatar = resizedImage
                self.text = output.notificationNumber
            }
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
