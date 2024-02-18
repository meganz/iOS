import MEGADesignToken
import MEGASwiftUI
import SwiftUI

struct PhotoLibraryZoomControl: View {
    @Binding var zoomState: PhotoLibraryZoomState
    @Environment(\.editMode) var editMode
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        zoomControl()
            .alignmentGuide(.trailing, computeValue: { d in d[.trailing] + 12})
            .alignmentGuide(.top, computeValue: { d in d[.top] - 5})
            .opacity(editMode?.wrappedValue.isEditing == true ? 0 : 1)
    }
    
    private var zoomInButtonForegroundColor: Color {
        if isDesignTokenEnabled {
            zoomState.canZoom(.in) ? (colorScheme == .light ? TokenColors.Background.surface1.swiftUI : TokenColors.Background.surface2.swiftUI) : UIColor.gray8E8E93.swiftUI
        } else {
            zoomState.canZoom(.in) ? MEGAAppColor.Photos.zoomButtonForeground.color : MEGAAppColor.Gray._8E8E93.color
        }
    }
    
    private var zoomOutButtonForegroundColor: Color {
        if isDesignTokenEnabled {
            zoomState.canZoom(.out) ? (colorScheme == .light ? TokenColors.Background.surface1.swiftUI : TokenColors.Background.surface2.swiftUI): UIColor.gray8E8E93.swiftUI
        } else {
            zoomState.canZoom(.out) ? MEGAAppColor.Photos.zoomButtonForeground.color : MEGAAppColor.Gray._8E8E93.color
        }
    }
    
    private var zoomControlBackgroundColor: Color {
        if isDesignTokenEnabled {
            colorScheme == .light ? TokenColors.Background.surface1.swiftUI : TokenColors.Background.surface2.swiftUI
        } else {
            .clear
        }
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
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .background(zoomControlBackgroundColor, in: RoundedRectangle(cornerRadius: 18))
        .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
    }
    
    // MARK: View Builders
    
    @ViewBuilder
    private func zoomInButton() -> some View {
        Button {
            zoomState.zoom(.in)
        } label: {
            if isDesignTokenEnabled {
                Image(systemName: "plus")
                    .imageScale(.large)
                    .foregroundColor(zoomState.canZoom(.in) ? TokenColors.Icon.primary.swiftUI : TokenColors.Icon.disabled.swiftUI)
            } else {
                Image(systemName: "plus")
                    .imageScale(.large)
            }
        }
        .foregroundColor(zoomInButtonForegroundColor)
        .disabled(!zoomState.canZoom(.in))
    }
    
    @ViewBuilder
    private func zoomOutButton() -> some View {
        Button {
            zoomState.zoom(.out)
        } label: {
            if isDesignTokenEnabled {
                Image(systemName: "minus")
                    .imageScale(.large)
                    .foregroundColor(zoomState.canZoom(.out) ? TokenColors.Icon.primary.swiftUI : TokenColors.Icon.disabled.swiftUI)
            } else {
                Image(systemName: "minus")
                    .imageScale(.large)
            }
        }
        .foregroundColor(zoomOutButtonForegroundColor)
        .disabled(!zoomState.canZoom(.out))
    }
}
