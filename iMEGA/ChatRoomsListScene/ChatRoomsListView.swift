import SwiftUI

@available(iOS 14.0, *)
struct ChatRoomsListView: View {
    @ObservedObject var viewModel: ChatRoomsListViewModel
    
    var body: some View {
        VStack {
            ChatTabsSelectorView(chatMode: viewModel.chatMode) { mode in
                viewModel.selectChatMode(mode)
            }
            
            if viewModel.isConnectedToNetwork == false {
                ChatRoomsEmptyView(emptyViewState: viewModel.emptyViewState())
            } else {
                ChatRoomsEmptyView(emptyViewState: viewModel.emptyViewState())
            }
        }
        .ignoresSafeArea()
    }
}


