import SwiftUI
import MEGASwiftUI

@available(iOS 14.0, *)
struct ChatRoomsListView: View {
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
                        searchString: Strings.Localizable.search,
                        cancelString: Strings.Localizable.cancel)
                    
                    if let archivedChatsViewState = viewModel.archiveChatsViewState() {
                        ChatRoomsTopRowView(state: archivedChatsViewState)
                            .onTapGesture {
                                archivedChatsViewState.action()
                            }
                            .listRowInsets(EdgeInsets())
                            .padding(10)
                    }
                    
                    let contactsOnMega = viewModel.contactsOnMegaViewState()
                    ChatRoomsTopRowView(state: contactsOnMega)
                    .onTapGesture {
                        contactsOnMega.action()
                    }
                    .listRowInsets(EdgeInsets())
                    .padding(10)
                                        
                    ForEach(chatRooms, id: \.self) { chatRoom in
                        ChatRoomView(viewModel: chatRoom)
                            .listRowInsets(EdgeInsets())
                    }
                }
                .listStyle(PlainListStyle())
                .gesture(DragGesture().onChanged({ _ in
                    UIApplication.shared.windows.forEach { $0.endEditing(false) }
                }))
            } else {
                ChatRoomsEmptyView(emptyViewState: viewModel.emptyViewState())
            }
        }
        .ignoresSafeArea()
    }
}
