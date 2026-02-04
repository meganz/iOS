import MEGAAssets
import MEGADesignToken
import MEGASwiftUI
import SwiftUI

public struct HomeView: View {
    // [IOS-11238] - Use ViewModel instead of @State
    @State var hidesFAB = false
    public init() {}

    public var body: some View {
        listContent
            .embedInScrollViewWithDirectionChangeHandler {
                hidesFAB = $0
            }
            .overlay(alignment: .bottomTrailing) {
                fabButton
                    .opacity(hidesFAB ? 0 : 1)
                    .animation(.easeInOut(duration: 0.3), value: hidesFAB)
            }
    }

    private var listContent: some View {
        LazyVStack(spacing: 0) {
            ForEach(0..<50, id: \.self) { index in
                RowView()
                    .background((index % 2 == 0 ? Color.red : Color.yellow))
            }
        }
    }

    private var fabButton: some View {
        VStack {
            RoundedPrimaryImageButton(image: MEGAAssets.Image.plus) {
                // [IOS-11238] - Handle the tap on FAB
            }
            .padding(TokenSpacing._5)
        }
    }

    // Debug only, will remove later
    private struct RowView: View {
        @State var height = 60.0
        @State var expanded = false
        var body: some View {
            Button {

                withAnimation {
                    if expanded { height /= 2 } else { height *= 2 }
                    expanded.toggle()
                }
            } label: {
                Text("Click to \(expanded ? "collapse" : "expand")")
            }
            .frame(height: height)
                .frame(maxWidth: .infinity)
        }
    }
}
