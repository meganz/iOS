import MEGADesignToken
import SwiftUI

struct ChatRoomParticipantPrivilegeView: View {
    
    let chatRoomParticipantPrivilege: ChatRoomParticipantPrivilege
    var body: some View {
        chatRoomParticipantPrivilege.image
            .renderingMode(.template)
            .colorMultiply(TokenColors.Icon.primary.swiftUI)
            .padding(.horizontal)
    }
}
