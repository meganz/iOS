import SwiftUI

struct MyAvatarIconView<AvatarObserver: MyAvatarObserver>: View {
    @StateObject var viewModel: MyAvatarIconViewModel<AvatarObserver>

    var body: some View {
        BadgeButtonSwfitUIWrapper(
            text: $viewModel.text,
            image: $viewModel.avatar
        ) { [weak viewModel] in
            guard let viewModel else { return }
            viewModel.openUserProfile()
        }
        .onAppear(perform: viewModel.onAppear)
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
