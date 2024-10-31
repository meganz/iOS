import MEGADesignToken
import MEGAL10n
import MEGAPresentation
import SwiftUI

public struct CreateAlbumCell: View {
    private let onTapHandler: (() -> Void)
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var orientation = UIDevice.current.orientation
    
    private var plusIconColor: Color {
        TokenColors.Icon.primary.swiftUI
    }
    
    private var backgroundColor: Color {
        TokenColors.Background.surface2.swiftUI
    }
    
    public init(onTapHandler: @escaping () -> Void) {
        self.onTapHandler = onTapHandler
    }
    
    public var body: some View {
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
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                Text(" ")
                    .font(.footnote)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            }
        }
        .onOrientationChanged { orientation = $0 }
        .foregroundStyle(TokenColors.Background.page.swiftUI)
    }
    
    private var iconSize: CGFloat {
        switch orientation {
        case .landscapeLeft, .landscapeRight:
            UIDevice.current.userInterfaceIdiom == .pad ? 35 : 25
        default:
            UIDevice.current.userInterfaceIdiom == .pad ? 25 : 20
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
