import SwiftUI

struct ChatRoomParticipantPrivilegeView: View {
    
    let chatRoomParticipantPrivilege: ChatRoomParticipantPrivilege
    var body: some View {
        Image(chatRoomParticipantPrivilege.image)
            .padding(.horizontal)
    }
}
