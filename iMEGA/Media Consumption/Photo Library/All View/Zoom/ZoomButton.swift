import SwiftUI

@available(iOS 14.0, *)
struct ZoomButton: View {
    @StateObject private var viewModel = ZoomViewModel()
    @Binding var zoomLevel: ZoomLevel
    
    var body: some View {
        HStack {
            Button(action: {
                zoomLevel = nextLevel(in: .zoomOut)
            }) {
                Image(systemName: "minus")
                    .imageScale(.large)
            }
            .foregroundColor(zoomLevel.value == PhotoLibraryConstants.fiveColumnsNumber ? Color.gray : Color(Colors.Photos.zoomButtonForeground.color))
            .disabled(zoomLevel.value == PhotoLibraryConstants.fiveColumnsNumber)
            
            Divider()
                .padding(EdgeInsets(top: 13, leading: 3, bottom: 13, trailing: 3))
            
            Button(action: {
                zoomLevel = nextLevel(in: .zoomIn)
            }) {
                Image(systemName: "plus")
                    .imageScale(.large)
            }
            .foregroundColor(zoomLevel.value == PhotoLibraryConstants.oneColumnNumber ? Color.gray : Color(Colors.Photos.zoomButtonForeground.color))
            .disabled(zoomLevel.value == PhotoLibraryConstants.oneColumnNumber)
        }
        .frame(width: 80, height: 40)
        .padding(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
        .blurryBackground(radius: 18)
        .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
        .alignmentGuide(.trailing, computeValue: { d in d[.trailing] + 12})
        .alignmentGuide(.top, computeValue: { d in d[.top] - 10})
    }
    
    // MARK: - Private
    
    private func nextLevel(in action: ZoomAction) -> ZoomLevel {
        viewModel.next(currentState: zoomLevel, action: action)
    }
}
