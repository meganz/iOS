import Combine
import MEGAAssets
import MEGADesignToken
import SwiftUI

@MainActor
final class MyAvatarIconViewModel: ObservableObject {
    @Published var avatar: UIImage?
    @Published var badge: String?
    @Published var avatarInitial: String = ""
    @Published var avatarBackgroundColor: Color = TokenColors.Text.primary.swiftUI
    
    private let avatarObserver: any MyAvatarObserverProtocol

    init(avatarObserver: some MyAvatarObserverProtocol) {
        self.avatarObserver = avatarObserver
        self.avatarObserver.avatarInitial.receive(on: DispatchQueue.main).assign(to: &$avatarInitial)
        self.avatarObserver.avatarBackgroundColor.receive(on: DispatchQueue.main).assign(to: &$avatarBackgroundColor)
        self.avatarObserver.avatar.receive(on: DispatchQueue.main).assign(to: &$avatar)
        self.avatarObserver.badge.receive(on: DispatchQueue.main).assign(to: &$badge)
    }
    
    func onAppear() async {
        await avatarObserver.onAppear()
    }
}
