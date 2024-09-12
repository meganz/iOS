import MEGADesignToken
import MEGASwift
import SwiftUI

struct ChatRoomsEmptyView: View {
    let emptyViewState: ChatRoomsEmptyViewState
    
    var body: some View {
        VStack {
            Group {
                ForEach(emptyViewState.topRows) { row in
                    ChatRoomsTopRowView(state: row)
                        .onTapGesture {
                            row.action()
                        }
                        .padding(8)
                    if emptyViewState.showDivider(for: row) {
                        Divider()
                            .padding(.leading)
                    }
                }
            }
            
            VStack {
                Spacer()
                
                ChatRoomsEmptyCenterView(
                    imageResource: emptyViewState.center.image,
                    title: emptyViewState.center.title,
                    description: emptyViewState.center.description
                )
                
                Spacer()
                
                if let button = emptyViewState.bottomButtons.first {
                    buttonView(from: button)
                    .padding(.horizontal, 70)
                    
                    Rectangle()
                        .fill(.clear)
                        .frame(maxWidth: .infinity, maxHeight: 35)
                }
            }
        }
        .background(.clear)
    }
    
    @ViewBuilder
    private func buttonView(from model: MenuButtonModel) -> some View {
        switch model.interaction {
        case .action(let action):
            ChatRoomsEmptyBottomButtonView(
                name: model.title,
                action: action
            )
        case .menu(let menu):
            ChatRoomsEmptyBottomButtonView(
                name: model.title,
                menus: menu
            )
        }
    }
}
