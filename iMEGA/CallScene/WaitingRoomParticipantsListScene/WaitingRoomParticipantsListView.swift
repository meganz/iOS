import MEGAL10n
import MEGAPresentation
import MEGASwiftUI
import SwiftUI

struct WaitingRoomParticipantsListView: View {
    @ObservedObject var viewModel: WaitingRoomParticipantsListViewModel
    
    var body: some View {
        ZStack {
            Color(MEGAAppColor.Black._2C2C2E.uiColor).edgesIgnoringSafeArea([.all])
            VStack {
                headerView
                searchBarView()
                    .padding(.horizontal, 30)
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
                    .foregroundColor(MEGAAppColor.White._FFFFFF.color)
                Text(Strings.Localizable.Chat.Call.WaitingRoom.participantsCount(viewModel.displayWaitingRoomParticipants.count))
                    .font(.caption)
                    .foregroundColor(MEGAAppColor.White._FFFFFF.color)
                    .opacity(0.8)
            }
            HStack {
                Spacer()
                Button(Strings.Localizable.Chat.Call.WaitingRoom.ParticipantsList.close) {
                    viewModel.closeTapped()
                }
                .padding(.trailing, 24)
                .foregroundColor(MEGAAppColor.Gray._D1D1D1.color)
                .font(.body.bold())
            }
        }
        .padding(16)
    }
    
    var admitAllView: some View {
        VStack {
            Button(Strings.Localizable.Chat.Call.WaitingRoom.Alert.Button.admitAll) {
                viewModel.admitAllTapped()
            }
            .font(.body.bold())
            .foregroundColor(MEGAAppColor.Green._00C29A.color)
            .frame(width: 288, height: 50, alignment: .center)
            .background(MEGAAppColor.Gray._363638.color)
            .cornerRadius(8)
            .shadow(color: MEGAAppColor.Black._000000.color.opacity(0.15), radius: 2, x: 0, y: 1)
        }
        .padding(EdgeInsets(top: 8, leading: 32, bottom: 42, trailing: 32))
    }
    
    @ViewBuilder
    private func searchBarView() -> some View {
        SearchBarView(
            text: $viewModel.searchText,
            isEditing: $viewModel.isSearchActive,
            placeholder: Strings.Localizable.search,
            cancelTitle: Strings.Localizable.cancel,
            isDesignTokenEnabled: DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken))
        .listRowSeparator(.hidden)
    }
}
