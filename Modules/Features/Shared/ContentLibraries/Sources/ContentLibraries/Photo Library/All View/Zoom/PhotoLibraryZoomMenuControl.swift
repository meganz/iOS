import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI

struct PhotoLibraryZoomMenuControl: View {
    @Binding var zoomState: PhotoLibraryZoomState

    private var selectedScaleFactor: PhotoLibraryZoomState.ScaleFactor {
        zoomState.scaleFactor
    }

    private func displayName(for scaleFactor: PhotoLibraryZoomState.ScaleFactor) -> String {
        switch scaleFactor {
        case .one:
            return Strings.Localizable.Media.PhotoLibrary.Zoom.Large.title
        case .three:
            return Strings.Localizable.default
        case .five:
            return Strings.Localizable.Media.PhotoLibrary.Zoom.Compact.title
        case .thirteen:
            return Strings.Localizable.Media.PhotoLibrary.Zoom.Smallest.title
        }
    }

    var body: some View {
        Menu {
            ForEach([PhotoLibraryZoomState.ScaleFactor.one, .three, .five], id: \.self) { scaleFactor in
                Button {
                    zoomState.scaleFactor = scaleFactor
                } label: {
                    HStack {
                        if scaleFactor == selectedScaleFactor {
                            Image(systemName: "checkmark")
                        }
                        Text(displayName(for: scaleFactor))
                    }
                }
            }
        } label: {
            MEGAAssets.Image.zoomGrid
                .imageScale(.large)
                .foregroundColor(TokenColors.Icon.primary.swiftUI)
                .frame(width: 44, height: 44)
        }
    }
}
