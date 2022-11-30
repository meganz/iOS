import SwiftUI
import MEGASwiftUI

struct PhotoLibraryZoomControl: View {
    @Binding var zoomState: PhotoLibraryZoomState
    @Environment(\.editMode) var editMode
    
    var body: some View {
        zoomControl()
            .alignmentGuide(.trailing, computeValue: { d in d[.trailing] + 12})
            .alignmentGuide(.top, computeValue: { d in d[.top] - 10})
            .opacity(editMode?.wrappedValue.isEditing == true ? 0 : 1)
    }
    
    // MARK: - Private
    private func zoomControl() -> some View {
        HStack {
            zoomOutButton()
            Divider()
                .padding(EdgeInsets(top: 13, leading: 3, bottom: 13, trailing: 3))
            zoomInButton()
        }
        .frame(width: 80, height: 40)
        .padding(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
        .blurryBackground(radius: 18)
        .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
    }
    
    private func zoomInButton() -> some View {
        Button {
            zoomState.zoom(.in)
        } label: {
            Image(systemName: "plus")
                .imageScale(.large)
        }
        .foregroundColor(zoomState.canZoom(.in) ? Color(Colors.Photos.zoomButtonForeground.color) : Color.gray)
        .disabled(!zoomState.canZoom(.in))
    }
    
    private func zoomOutButton() -> some View {
        Button {
            zoomState.zoom(.out)
        } label: {
            Image(systemName: "minus")
                .imageScale(.large)
        }
        .foregroundColor(zoomState.canZoom(.out) ? Color(Colors.Photos.zoomButtonForeground.color) : Color.gray)
        .disabled(!zoomState.canZoom(.out))
    }
}
