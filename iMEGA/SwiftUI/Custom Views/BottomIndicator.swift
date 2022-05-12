import SwiftUI

struct BottomIndicator: View {
    var width: CGFloat = 0
    var height: CGFloat = 0
    var offset: CGFloat = 0
    var color: Color = .red
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.clear)
                .frame(width: width, height: height)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Rectangle()
                .fill()
                .frame(width: width / 2, height: height)
                .frame(maxWidth: .infinity, alignment: .leading)
                .offset(x: offset)
                .foregroundColor(color)
        }
    }
}
