import SwiftUI

struct MyAvatarIconView<AvatarObserver: MyAvatarObserver>: View {
    @ObservedObject var viewModel: MyAvatarIconViewModel<AvatarObserver>

    var body: some View {
        BadgeButtonSwfitUIWrapper(
            text: $viewModel.text,
            image: $viewModel.avatar
        ) { [weak viewModel] in
            guard let viewModel else { return }
            viewModel.openUserProfile()
        }
    }
}

#Preview {
    MyAvatarIconView(
        viewModel: .init(
            avatarObserver: MockMyAvatarUpdatesObserver(),
            onAvatarTapped: {}
        )
    )
}
