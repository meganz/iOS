import MEGADesignToken
import MEGASwift
import SwiftUI

struct NewChatRoomsEmptyView: View {
    var state: ChatRoomsEmptyViewState
    var maxHeight: CGFloat = 50
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var body: some View {
        VStack(
            spacing: 0
        ) {
            // making sure description is not clipped in:
            // 1. iPhone landscape
            // 2. ContactsViewController table footer view
            if maxHeight > 0 && verticalSizeClass != .compact {
                Spacer()
                    .frame(maxHeight: maxHeight)
            } else {
                Spacer()
            }
            
            VStack(spacing: 24) {
                NewChatRoomsEmptyCenterView(state: state.center)
                    .padding(.leading, 30)
                    .padding(.trailing, 30)
                    .frame(maxWidth: horizontalSizeClass == .regular ? 400 : .infinity)
                
                AdaptiveStack(spacing: 24) {
                    ForEach(state.bottomButtons) { button in
                        MenuCapableButton(state: button)
                    }
                }
            }
            
            Spacer()
        }
        .background(.clear)
    }
}
/// Stack View that is Horizontal when vertical size class is compact (ie. iPhone landscape) and VStack otherwise
/// Carries spacing into each of them
struct AdaptiveStack<Content: View>: View {
    let spacing: CGFloat
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @ViewBuilder var content: () -> Content
    init(
        spacing: CGFloat,
        @ViewBuilder content: @escaping  () -> Content
    ) {
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        if verticalSizeClass == .compact {
            HStack(spacing: spacing) {
                content()
            }
        } else {
            VStack(spacing: spacing) {
                content()
            }
        }
    }
}
