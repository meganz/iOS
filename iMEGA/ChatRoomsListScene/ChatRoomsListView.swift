import SwiftUI

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
            } else if let chatListItems = viewModel.chatListItems {
                List {
                    let topRowViewState = viewModel.topRowViewState()
                    Button {
                        topRowViewState.action()
                    } label: {
                        ChatRoomsTopRowView(
                            imageAsset: topRowViewState.imageAsset,
                            description: topRowViewState.description
                        )
                    }
                    .listRowInsets(EdgeInsets())
                    .buttonStyle(.plain)
                    .padding(10)
                    
                    ForEach(chatListItems, id: \.self) { chatListItem in
                        ChatListItemView(chatListItem: chatListItem)
                        .listRowInsets(EdgeInsets())
                        .onTapGesture {
                            viewModel.tapped(chatListItem: chatListItem)
                        }
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
