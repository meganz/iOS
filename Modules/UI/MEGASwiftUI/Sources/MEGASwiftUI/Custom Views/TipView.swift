import SwiftUI

public struct TipView: View {
    
    public enum TipArrowDirection {
        case up
        case down
    }
    
    let tip: Tip
    let arrowDirection: TipArrowDirection
    let width: CGFloat
    let contentOffsetX: CGFloat
    let contentOffsetY: CGFloat
    
    @Environment(\.colorScheme) var colorScheme

    public init(tip: Tip,
                arrowDirection: TipArrowDirection = .up,
                width: CGFloat = 241,
                contentOffsetX: CGFloat = 0,
                contentOffsetY: CGFloat = 0) {
        self.tip = tip
        self.arrowDirection = arrowDirection
        self.width = width
        self.contentOffsetX = contentOffsetX
        self.contentOffsetY = contentOffsetY
    }

    public var body: some View {
        VStack(spacing: 0) {
            if arrowDirection == .up {
                TipArrowShape()
                    .foregroundColor(colorScheme == .dark ? .white : Color(red: 58/255, green: 58/255, blue: 60/255))
                    .frame(width: 16, height: 10)
                TipContentView(tip: tip, width: width)
                    .offset(x: contentOffsetX, y: contentOffsetY)
            } else {
                TipContentView(tip: tip, width: width)
                    .offset(x: contentOffsetX, y: contentOffsetY)
                TipArrowShape()
                    .foregroundColor(colorScheme == .dark ? .white : Color(red: 58/255, green: 58/255, blue: 60/255))
                    .frame(width: 16, height: 10)
                    .rotationEffect(.degrees(180))
            }
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
            if #available(iOS 15.0, *) {
                Text(attributedBold(text: tip.message, boldText: tip.boldMessage))
                    .foregroundColor(colorScheme == .dark ? .black : .white)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(tip.message)
                    .font(.caption)
                    .foregroundColor(colorScheme == .dark ? .black : .white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer().frame(height: 12)
            Button {
                withAnimation {
                    tip.buttonAction?()
                }
            } label: {
                Text(tip.buttonTitle)
                    .font(.system(size: 12))
                    .bold()
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

@available(iOS 15.0, *)
extension View {
    func attributedBold(text: String, boldText: String?, font: Font = .caption) -> AttributedString {
        var result = AttributedString(text)
        result.font = font
        guard let boldText = boldText else {
            return result
        }
        if let range = result.range(of: boldText) {
            result[range].font = font.bold()
        }
        return result
    }
}

struct TipView_Previews: PreviewProvider {
    
    private struct Shim: View {
        var body: some View {
            VStack {
                TipView(tip: Tip(title: "Start meeting",
                                 message: "You can start the meeting before its scheduled time by tapping Start meeting in the meeting room.",
                                 buttonTitle: "Got it",
                                 buttonAction: nil)
                )
                
                TipView(tip: Tip(title: "Start meeting",
                                 message: "You can start the meeting before its scheduled time by tapping Start meeting in the meeting room.",
                                 buttonTitle: "Got it",
                                 buttonAction: nil),
                        arrowDirection: .down
                )
                
                TipView(tip: Tip(title: "Start meeting",
                                 message: "You can start the meeting before its scheduled time by tapping Start meeting in the meeting room.",
                                 boldMessage: "Start meeting",
                                 buttonTitle: "Got it",
                                 buttonAction: nil)
                )
            }
        }
    }
    
    static var previews: some View {
        Shim()
    }
}
