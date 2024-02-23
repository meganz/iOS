import MEGADesignToken
import MEGAL10n
import MEGAPresentation
import SwiftUI

struct CreateAlbumCell: View {
    let onTapHandler: (() -> Void)
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var orientation = UIDevice.current.orientation
    
    private var plusIconColor: Color {
        if isDesignTokenEnabled {
            TokenColors.Icon.primary.swiftUI
        } else {
            colorScheme == .light ? MEGAAppColor.Gray._515151.color : MEGAAppColor.White._FCFCFC.color
        }
    }
    
    private var backgroundColor: Color {
        isDesignTokenEnabled ? TokenColors.Background.surface2.swiftUI : MEGAAppColor.Gray._EBEBEB.color
    }
    
    var body: some View {
        Button(action: onTapHandler, label: content)
            .buttonStyle(.plain)
    }
    
    func content() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .center) {
                backgroundColor
                    .aspectRatio(contentMode: .fill)
                    .cornerRadius(6)
                
                Image(systemName: "plus")
                    .font(.system(size: iconSize))
                    .foregroundColor(plusIconColor)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(Strings.Localizable.CameraUploads.Albums.CreateAlbum.title)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .font(.caption)
                    .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : Color.primary)
                Text(" ")
                    .font(.footnote)
                    .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.secondary.swiftUI : Color.secondary)
            }
        }
        .onOrientationChanged { orientation = $0 }
        .foregroundStyle(isDesignTokenEnabled ? TokenColors.Background.page.swiftUI : Color.clear)
    }
    
    private var iconSize: CGFloat {
        switch orientation {
        case .landscapeLeft, .landscapeRight:
            UIDevice.current.iPad ? 35 : 25
        default:
            UIDevice.current.iPad ? 25 : 20
        }
    }
}

#Preview {
    CreateAlbumCell(onTapHandler: { })
}

#Preview {
    CreateAlbumCell(onTapHandler: { })
        .preferredColorScheme(.dark)
}
