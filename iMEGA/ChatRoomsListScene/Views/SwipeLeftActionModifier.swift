import SwiftUI

extension View {
    func swipeLeftActions(labels: [SwipeActionLabel], buttonWidth: CGFloat) -> some View {
        modifier(SwipeLeftActionModifier(labels: labels, buttonWidth: buttonWidth))
    }
}

struct SwipeLeftActionModifier: ViewModifier  {
    @State private var offset: CGFloat = 0
    @State private var oldOffset: CGFloat = 0
    @State private var buttonsVisible = false

    let labels: [SwipeActionLabel]
    let buttonWidth: CGFloat
    let minTrailingOffset: CGFloat
    
    init(labels: [SwipeActionLabel], buttonWidth: CGFloat) {
        self.labels = labels
        self.buttonWidth = buttonWidth
        self.minTrailingOffset = CGFloat(labels.count) * buttonWidth * -1
    }
    
    private func reset() {
        buttonsVisible = false
        offset = 0
        oldOffset = 0
    }
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .contentShape(Rectangle())
                .offset(x: offset)
                .gesture(
                    DragGesture(minimumDistance: 15, coordinateSpace: .local)
                        .onChanged { (value) in
                            let totalSlide = value.translation.width + oldOffset
                            if Int(minTrailingOffset)...0 ~= Int(totalSlide) {
                                withAnimation{
                                    offset = totalSlide
                                }
                            }
                        }
                        .onEnded { value in
                            withAnimation {
                                if buttonsVisible && value.translation.width > 20 {
                                    reset()
                                } else if offset < -25 {
                                    buttonsVisible = true
                                    offset = minTrailingOffset
                                    oldOffset = offset
                                } else {
                                    reset()
                                }
                            }
                        }
                )
            
            GeometryReader { proxy in
                HStack(spacing: 0) {
                    Spacer()
                    HStack(spacing: 0) {
                        ForEach(labels) { label in
                            if let image = UIImage(named: label.imageName) {
                                Button(action: {
                                    withAnimation {
                                        reset()
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
                                        label.action()
                                    }
                                }, label: {
                                    Image(uiImage: image)
                                        .foregroundColor(.white)
                                        .frame(width: buttonWidth)
                                        .frame(maxHeight: .infinity)
                                })
                                .buttonStyle(BorderlessButtonStyle())
                                .background(label.backgroundColor)
                            }
                        }
                    }
                    .offset(x: (-1 * minTrailingOffset) + offset)
                }
            }
        }
    }
}
