import MEGADesignToken
import MEGASwift
import SwiftUI

struct NewChatRoomsEmptyView: View {
    var state: ChatRoomsEmptyViewState
    var topPadding: CGFloat = 0
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var body: some View {
        VStack(
            spacing: 0
        ) {
            if topPadding > 0 && verticalSizeClass != .compact {
                Spacer()
                    .frame(height: topPadding)
            } else {
                Spacer()
            }
            
            VStack(spacing: 16) {
                NewChatRoomsEmptyCenterView(state: state.center)
                    .padding(.leading, 30)
                    .padding(.trailing, 30)
                    .frame(maxWidth: horizontalSizeClass == .regular ? 400 : .infinity)
                
                AdaptiveStack(spacing: 16) {
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
