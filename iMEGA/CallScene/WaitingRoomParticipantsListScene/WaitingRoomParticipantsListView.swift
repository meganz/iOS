import MEGADesignToken
import MEGAL10n
import MEGAPresentation
import MEGASwiftUI
import SwiftUI

struct WaitingRoomParticipantsListView: View {
    @ObservedObject var viewModel: WaitingRoomParticipantsListViewModel
    
    var body: some View {
        ZStack {
            Color(.black2C2C2E).edgesIgnoringSafeArea([.all])
            VStack(spacing: 0) {
                headerView
                searchBarView()
                    .padding(.horizontal, 30)
                Spacer()
                    .frame(height: 8)
                bannerView
                ScrollView {
                    ForEach(viewModel.displayWaitingRoomParticipants) { participantViewModel in
                        WaitingRoomParticipantView(viewModel: participantViewModel)
                            .listRowInsets(EdgeInsets())
                    }
                }
                .padding(.horizontal)
               admitAllView
            }
            .edgesIgnoringSafeArea([.top, .bottom])
        }
    }
    
    var headerView: some View {
        ZStack {
            VStack {
                Text(Strings.Localizable.Chat.Call.WaitingRoom.ParticipantsList.title)
                    .font(.subheadline)
                    .foregroundColor(TokenColors.Text.primary.swiftUI)
                Text(Strings.Localizable.Chat.Call.WaitingRoom.participantsCount(viewModel.displayWaitingRoomParticipants.count))
                    .font(.caption)
                    .foregroundColor(TokenColors.Text.primary.swiftUI)
                    .opacity(0.8)
            }
            HStack {
                Spacer()
                Button(Strings.Localizable.Chat.Call.WaitingRoom.ParticipantsList.close) {
                    viewModel.closeTapped()
                }
                .padding(.trailing, 24)
                .foregroundColor(.grayD1D1D1)
                .font(.body.bold())
            }
        }
        .padding(16)
    }
    
    @ViewBuilder
    var bannerView: some View {
        if let config = viewModel.bannerConfig {
            BannerView(config: config)
                .font(.footnote)
        }
    }
    
    var admitAllView: some View {
        VStack {
            Button(Strings.Localizable.Chat.Call.WaitingRoom.Alert.Button.admitAll) {
                viewModel.admitAllTapped()
            }
            .opacity(viewModel.admitAllButtonDisabled ? 0.25 : 1.0)
            .disabled(viewModel.admitAllButtonDisabled)
            .font(.body.bold())
            .foregroundColor(TokenColors.Link.primary.swiftUI)
            .frame(width: 288, height: 50, alignment: .center)
            .background(.gray363638)
            .cornerRadius(8)
            .shadow(color: .black000000.opacity(0.15), radius: 2, x: 0, y: 1)
        }
        .padding(EdgeInsets(top: 8, leading: 32, bottom: 42, trailing: 32))
    }
    
    @ViewBuilder
    private func searchBarView() -> some View {
        SearchBarView(
            text: $viewModel.searchText,
            isEditing: $viewModel.isSearchActive,
            placeholder: Strings.Localizable.search,
            cancelTitle: Strings.Localizable.cancel)
        .listRowSeparator(.hidden)
    }
}
