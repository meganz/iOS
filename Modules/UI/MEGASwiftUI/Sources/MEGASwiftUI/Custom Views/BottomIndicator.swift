import SwiftUI

public struct BottomIndicator: View {
    var width: CGFloat = 0
    var height: CGFloat = 0
    var offset: CGFloat = 0
    var color: Color = .red
    
    public init(width: CGFloat, height: CGFloat, offset: CGFloat, color: Color) {
        self.width = width
        self.height = height
        self.offset = offset
        self.color = color
    }
    
    public var body: some View {
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
