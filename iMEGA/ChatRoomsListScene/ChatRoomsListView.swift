import SwiftUI
import MEGASwiftUI

struct ChatRoomsListView: View {
    
    @ObservedObject var viewModel: ChatRoomsListViewModel

    var body: some View {
        VStack (spacing: 0) {
            ChatTabsSelectorView(chatViewMode: viewModel.chatViewMode) { mode in
                viewModel.selectChatMode(mode)
            }
            
            if let activeCallViewModel = viewModel.activeCallViewModel {
                ChatRoomActiveCallView(viewModel: activeCallViewModel)
            }
            
            if viewModel.isConnectedToNetwork == false {
                ChatRoomsEmptyView(emptyViewState: viewModel.noNetworkEmptyViewState())
            } else {
                if viewModel.chatViewMode == .chats {
                    if let chatRooms = viewModel.displayChatRooms {
                        List {
                            SearchBarView(
                                text: $viewModel.searchText,
                                isEditing: $viewModel.isSearchActive,
                                placeholder: Strings.Localizable.search,
                                cancelTitle: Strings.Localizable.cancel)
                            
                            if chatRooms.isNotEmpty {
                                if let archivedChatsViewState = viewModel.archiveChatsViewState(), !viewModel.isSearchActive {
                                    ChatRoomsTopRowView(state: archivedChatsViewState)
                                        .onTapGesture {
                                            archivedChatsViewState.action()
                                        }
                                        .listRowInsets(EdgeInsets())
                                        .padding(10)
                                }
                                
                                if !viewModel.isSearchActive {
                                    let contactsOnMega = viewModel.contactsOnMegaViewState()
                                    ChatRoomsTopRowView(state: contactsOnMega)
                                        .onTapGesture {
                                            contactsOnMega.action()
                                        }
                                        .listRowInsets(EdgeInsets())
                                        .padding(10)
                                }
                                
                                ForEach(chatRooms) { chatRoom in
                                    ChatRoomView(viewModel: chatRoom)
                                        .listRowInsets(EdgeInsets())
                                }
                            }
                        }
                        .listStyle(.plain)
                        .overlay(
                            VStack {
                                if viewModel.isChatRoomEmpty {
                                    ChatRoomsEmptyView(emptyViewState: viewModel.searchEmptyViewState())
                                }
                            }
                            , alignment: .center
                        )
                    } else {
                        ChatRoomsEmptyView(emptyViewState: viewModel.emptyChatRoomsViewState())
                    }
                }
                
                if viewModel.chatViewMode == .meetings {
                    if let futureMeetings = viewModel.displayFutureMeetings,
                       let pastMeetings = viewModel.displayPastMeetings {
                            List {
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
                                
                                if pastMeetings.isNotEmpty || futureMeetings.isNotEmpty {
                                    ForEach(futureMeetings, id: \.title) { futureMeetingSection in
                                        MeetingsListHeaderView(title: futureMeetingSection.title)
                                            .listRowInsets(EdgeInsets())
                                        ForEach(futureMeetingSection.items) { futureMeeting in
                                            FutureMeetingRoomView(viewModel: futureMeeting)
                                                .listRowInsets(EdgeInsets())
                                        }
                                    }
                                    
                                    MeetingsListHeaderView(title: Strings.Localizable.Chat.Listing.SectionHeader.PastMeetings.title)
                                        .listRowInsets(EdgeInsets())
                                    ForEach(pastMeetings) { pastMeeting in
                                        ChatRoomView(viewModel: pastMeeting)
                                            .listRowInsets(EdgeInsets())
                                    }
                                }
                            }
                            .listStyle(.plain)
                            .overlay(
                                VStack {
                                    if viewModel.isChatRoomEmpty {
                                        ChatRoomsEmptyView(emptyViewState: viewModel.searchEmptyViewState())
                                    }
                                }
                                , alignment: .center
                            )
                    } else {
                        ChatRoomsEmptyView(emptyViewState: viewModel.emptyChatRoomsViewState())
                    }
                }
            }
            Rectangle()
                .frame(maxWidth: .infinity, maxHeight: viewModel.bottomViewHeight)
        }
        .ignoresSafeArea()
        .onAppear {
            viewModel.loadChatRooms()
        }
        .onDisappear {
            viewModel.cancelLoading()
        }
    }
}
