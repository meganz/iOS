import SwiftUI

@available(iOS 14.0, *)
struct ChatRoomsListView: View {
    @ObservedObject var viewModel: ChatRoomsListViewModel
    
    var body: some View {
        VStack {
            ChatTabsSelectorView(chatMode: viewModel.chatMode) { mode in
                viewModel.selectChatMode(mode)
            }
            
            if let emptyViewState = viewModel.emptyViewState {
                ChatRoomsEmptyView(emptyViewState: emptyViewState)
            }
        }
        .ignoresSafeArea()
    }
}


