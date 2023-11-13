import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct WaitingRoomParticipantsListView: View {
    @ObservedObject var viewModel: WaitingRoomParticipantsListViewModel
    
    var body: some View {
        ZStack {
            Color(Colors.General.Black._2c2c2e.name).edgesIgnoringSafeArea([.all])
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
                    .foregroundColor(.white)
                Text(Strings.Localizable.Chat.Call.WaitingRoom.participantsCount(viewModel.displayWaitingRoomParticipants.count))
                    .font(.caption)
                    .foregroundColor(.white)
                    .opacity(0.8)
            }
            HStack {
                Spacer()
                Button(Strings.Localizable.Chat.Call.WaitingRoom.ParticipantsList.close) {
                    viewModel.closeTapped()
                }
                .padding(.trailing, 24)
                .foregroundColor(Color(UIColor.grayD1D1D1))
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
            .foregroundColor(Color(.green00C29A))
            .frame(width: 288, height: 50, alignment: .center)
            .background(Color(Colors.General.Gray._363638.name))
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
        }
        .padding(EdgeInsets(top: 8, leading: 32, bottom: 42, trailing: 32))
    }
    
    @ViewBuilder
    private func searchBarView() -> some View {
        if #available(iOS 15.0, *) {
            SearchBarView(
                text: $viewModel.searchText,
                isEditing: $viewModel.isSearchActive,
                placeholder: Strings.Localizable.search,
                cancelTitle: Strings.Localizable.cancel)
            .listRowSeparator(.hidden)
        } else {
            SearchBarView(
                text: $viewModel.searchText,
                isEditing: $viewModel.isSearchActive,
                placeholder: Strings.Localizable.search,
                cancelTitle: Strings.Localizable.cancel)
        }
    }
}
