import SwiftUI

public struct TipView: View {
    let tip: Tip
    let width: CGFloat
    let contentOffsetX: CGFloat
    let contentOffsetY: CGFloat
    
    @Environment(\.colorScheme) var colorScheme

    public init(tip: Tip,
                width: CGFloat = 241,
                contentOffsetX: CGFloat = 0,
                contentOffsetY: CGFloat = 0) {
        self.tip = tip
        self.width = width
        self.contentOffsetX = contentOffsetX
        self.contentOffsetY = contentOffsetY
    }

    public var body: some View {
        VStack(spacing: 0) {
            TipArrowShape()
                .foregroundColor(colorScheme == .dark ? .white : Color(red: 58/255, green: 58/255, blue: 60/255))
                .frame(width: 16, height: 10)
            TipContentView(tip: tip, width: width)
                .offset(x: contentOffsetX, y: contentOffsetY)
        }.shadow(color: Color.black.opacity(0.25), radius: 4, y: 4)
    }
}

struct TipContentView: View {
    let tip: Tip
    let width: CGFloat
    
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(tip.title)
                .font(.footnote)
                .bold()
                .foregroundColor(colorScheme == .dark ? .black : .white)
                .fixedSize(horizontal: false, vertical: true)
            Spacer().frame(height: 8)
            Text(tip.message)
                .font(.caption)
                .foregroundColor(colorScheme == .dark ? .black : .white)
                .fixedSize(horizontal: false, vertical: true)
            Spacer().frame(height: 12)
            Button {
                withAnimation {
                    tip.buttonAction?()
                }
            } label: {
                Text(tip.buttonTitle)
                    .font(.system(size: 12))
                    .foregroundColor(colorScheme == .dark ? .black : .white)
                    .underline(true)
            }
        }
        .padding(16)
        .frame(width: width)
        .background(colorScheme == .dark ? .white : Color(red: 58/255, green: 58/255, blue: 60/255))
        .cornerRadius(8)
    }
}

struct TipArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let topPoint =  CGPoint(x: rect.midX, y: rect.minY)
        let bottomLeftPoint = CGPoint(x: rect.minX, y: rect.maxY)
        let bottomRightPoint = CGPoint(x: rect.maxX, y: rect.maxY)
        
        path.move(to: topPoint)
        path.addLine(to: bottomLeftPoint)
        path.addLine(to: bottomRightPoint)
        path.addArc(tangent1End: topPoint, tangent2End: bottomLeftPoint, radius: 2)
        
        return path
    }
}

struct TipView_Previews: PreviewProvider {
    static var previews: some View {
        TipView(tip: Tip(title: "Schedule meeting",
                         message: "You can now schedule one-off and recurring meetings.",
                         buttonTitle: "Got it",
                         buttonAction: nil)
        )
        .padding(20)
        .previewLayout(.sizeThatFits)
        
        TipView(tip: Tip(title: "Schedule meeting",
                         message: "You can now schedule one-off and recurring meetings.",
                         buttonTitle: "Got it",
                         buttonAction: nil)
        )
        .padding(20)
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.dark)
    }
}
