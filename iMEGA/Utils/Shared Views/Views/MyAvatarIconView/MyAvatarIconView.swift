import SwiftUI

struct MyAvatarIconView<AvatarObserver: MyAvatarObserver>: View {
    @ObservedObject var viewModel: MyAvatarIconViewModel<AvatarObserver>

    var body: some View {
        Button(action: {
            viewModel.openUserProfile()
        }, label: {
            BadgeButtonSwfitUIWrapper(
                text: $viewModel.text,
                image: $viewModel.avatar
            )
        })
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
