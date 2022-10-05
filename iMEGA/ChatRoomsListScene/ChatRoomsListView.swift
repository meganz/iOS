import SwiftUI

struct ChatRoomsListView: View {
    @ObservedObject var viewModel: ChatRoomsListViewModel
    
    var body: some View {
        ChatTabsSelectorView(chatMode: viewModel.chatMode) { mode in
            viewModel.selectChatMode(mode)
        }
        List {
            
        }
    }
}
