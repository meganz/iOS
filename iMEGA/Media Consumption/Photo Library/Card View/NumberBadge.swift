import SwiftUI

struct NumberBadge: View {
    let title: String
    let backgroundColor = Color(Colors.MediaConsumption.photoNumbersBackground.color)
    
    var body: some View {
        Text(title)
            .font(.system(size: 16))
            .fontWeight(.semibold)
            .padding(EdgeInsets(top: 5, leading: 8, bottom: 5, trailing: 8))
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 13.5))
    }
}
