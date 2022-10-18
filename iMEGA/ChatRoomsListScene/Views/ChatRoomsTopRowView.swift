import SwiftUI

struct ChatRoomsTopRowView: View {
    let state: ChatRoomsTopRowViewState
    private let discolureIndicator = "chevron.right"
    
    var body: some View {
        HStack {
            if let image = Image(uiImage: state.image) {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
            }
            
            Text(state.description)
                .font(.subheadline)
            
            Spacer()
            
            if let rightDetail = state.rightDetail {
                Text(rightDetail)
                    .font(.body)
            }
            
            Image(systemName: discolureIndicator)
                .foregroundColor(.gray.opacity(0.6))
        }
    }
}
