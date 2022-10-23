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
            
            if viewModel.isConnectedToNetwork == false {
                ChatRoomsEmptyView(emptyViewState: viewModel.emptyViewState())
            } else if let chatRooms = viewModel.displayChatRooms {
                List {
                    SearchBarView(
                        text: $viewModel.searchText,
                        placeholder: Strings.Localizable.search,
                        cancelTitle: Strings.Localizable.cancel)
                    
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
                                        
                    ForEach(chatRooms, id: \.chatListItem.chatId) { chatRoom in
                        ChatRoomView(viewModel: chatRoom)
                            .listRowInsets(EdgeInsets())
                            .padding(.leading, editMode?.wrappedValue == .active ? -40 : 0)
                    }
                }
                .listStyle(PlainListStyle())
            } else {
                ChatRoomsEmptyView(emptyViewState: viewModel.emptyViewState())
            }
        }
        .ignoresSafeArea()
    }
}
