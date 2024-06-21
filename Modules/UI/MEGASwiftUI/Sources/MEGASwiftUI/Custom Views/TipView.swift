import SwiftUI

public struct TipView: View {
    
    public enum TipArrowDirection {
        case up
        case down
        case left
        case right
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
        switch arrowDirection {
        case .up:
            VStack(spacing: 0) {
                arrowView()
                contentView()
            }
        case .down:
            VStack(spacing: 0) {
                contentView()
                arrowView()
            }
        case .left:
            HStack(spacing: 0) {
                arrowView()
                contentView()
            }
        case .right:
            HStack(spacing: 0) {
                contentView()
                arrowView()
            }
        }
    }
    
    @ViewBuilder
    private func contentView() -> some View {
        TipContentView(tip: tip, width: width)
            .offset(x: contentOffsetX, y: contentOffsetY)
            .shadow(color: Color.black.opacity(0.25), radius: 4, y: 4)
    }
    
    @ViewBuilder
    private func arrowView() -> some View {
        TipArrowShape()
            .foregroundColor(colorScheme == .dark ? .white : Color(red: 58/255, green: 58/255, blue: 60/255))
            .frame(width: 10, height: 10)
            .rotationEffect(.degrees(rotationDegrees()))
    }
    
    private func rotationDegrees() -> Double {
        switch arrowDirection {
        case .up:
            return 0
        case .down:
            return 180
        case .left:
            return 270
        case .right:
            return 90
        }
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
            if let message = tip.message {
                Spacer().frame(height: 8)
                Text(attributedBold(text: message, boldText: tip.boldMessage))
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
        .frame(width: width, alignment: .leading)
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

#Preview {
    VStack {
        TipView(tip: Tip(title: "Start meeting",
                         message: "You can start the meeting before its scheduled time by tapping Start meeting in the meeting room.",
                         buttonTitle: "Got it",
                         buttonAction: nil)
        )
    }
}

#Preview {
    VStack {
        TipView(tip: Tip(title: "Start meeting",
                         message: "You can start the meeting before its scheduled time by tapping Start meeting in the meeting room.",
                         buttonTitle: "Got it",
                         buttonAction: nil),
                arrowDirection: .down
        )
    }
}

#Preview {
    VStack {
        TipView(tip: Tip(title: "Start meeting",
                         message: "You can start the meeting before its scheduled time by tapping Start meeting in the meeting room.",
                         buttonTitle: "Got it",
                         buttonAction: nil)
        )
    }
}
