import SwiftUI
import MEGASwiftUI

@available(iOS 14.0, *)
struct ChatRoomsListView: View {
    @Environment(\.editMode) private var editMode
    
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
            } else if let chatRooms = viewModel.displayChatRooms {
                List {
                    SearchBarView(
                        text: $viewModel.searchText,
                        placeholder: Strings.Localizable.search,
                        cancelTitle: Strings.Localizable.cancel)
                    
                    if chatRooms.count > 0 {
                        if let archivedChatsViewState = viewModel.archiveChatsViewState(), editMode?.wrappedValue == .inactive {
                            ChatRoomsTopRowView(state: archivedChatsViewState)
                                .onTapGesture {
                                    archivedChatsViewState.action()
                                }
                                .listRowInsets(EdgeInsets())
                                .padding(10)
                        }
                        
                        if editMode?.wrappedValue == .inactive {
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
                .animation(.default, value: chatRooms)
                .listStyle(PlainListStyle())
                .overlay(
                    VStack {
                        if chatRooms.count == 0 {
                            ChatRoomsEmptyView(emptyViewState: viewModel.searchEmptyViewState())
                        }
                    }
                    , alignment: .center
                )
                Rectangle()
                    .frame(maxWidth: .infinity, maxHeight: viewModel.bottomViewHeight)
            } else {
                ChatRoomsEmptyView(emptyViewState: viewModel.emptyChatRoomsViewState())
            }
        }
        .ignoresSafeArea()
    }
}
