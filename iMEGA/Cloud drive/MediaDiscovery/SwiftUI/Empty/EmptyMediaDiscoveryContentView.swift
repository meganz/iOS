import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct EmptyMediaDiscoveryContentView: View {
    
    let image: UIImage
    let title: String
    let menuActionHandler: (EmptyMediaDiscoveryContentMenuAction) -> Void
    
    var body: some View {
        VStack {
            Spacer()
            centreContent
            Spacer()
            actionContent
        }
    }
    
    @ViewBuilder
    var centreContent: some View {
        VStack(alignment: .center, spacing: 16) {
            Image(uiImage: image)
                .resizable()
                .frame(width: 120, height: 120)
            Text(title)
                .font(.body)
        }
    }
    
    @ViewBuilder
    var actionContent: some View {
        VStack {
            Menu(content: {
                ForEach(EmptyMediaDiscoveryContentMenuAction.allCases.reversed()) { menuItem in
                    Button(
                        action: { menuActionHandler(menuItem) },
                        label: { Label { Text(menuItem.title) } icon: { menuItem.menuIcon } }
                    )
                }
            }, label: {
                Text(Strings.Localizable.addFiles)
                    .font(.body.weight(.semibold))
                    .foregroundColor(Color.white)
                    .frame(width: 288, height: 50)
            })
            .background(Colors.Views.turquoise.swiftUIColor)
            .cornerRadius(8, corners: .allCorners)
            .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 1)
        }
        .padding(.bottom, 35)
    }
}

private extension EmptyMediaDiscoveryContentMenuAction {
     var title: String {
        switch self {
        case .choosePhotoVideo:
            return Strings.Localizable.choosePhotoVideo
        case .capturePhotoVideo:
            return Strings.Localizable.capturePhotoVideo
        case .importFromFiles:
            return Strings.Localizable.CloudDrive.Upload.importFromFiles
        case .scanDocument:
            return Strings.Localizable.scanDocument
        case .newFolder:
            return Strings.Localizable.newFolder
        case .newTextFile:
            return Strings.Localizable.newTextFile
        }
    }
    
    var menuIcon: Image? {
        switch self {
        case .choosePhotoVideo:
            return Asset.Images.NodeActions.saveToPhotos.swiftUIImage
        case .capturePhotoVideo:
            return Asset.Images.ActionSheetIcons.capture.swiftUIImage
        case .importFromFiles:
            return Asset.Images.InfoActions.import.swiftUIImage
        case .scanDocument:
            return Asset.Images.ActionSheetIcons.scanDocument.swiftUIImage
        case .newFolder:
            return Asset.Images.ActionSheetIcons.newFolder.swiftUIImage
        case .newTextFile:
            return Asset.Images.NodeActions.textfile.swiftUIImage
        }
    }
}

struct EmptyMediaDiscoveryContentView_Previews: PreviewProvider {
    
    static var previews: some View {
        EmptyMediaDiscoveryContentView(
            image: Asset.Images.EmptyStates.folderEmptyState.image,
            title: Strings.Localizable.emptyFolder,
            menuActionHandler: { _ in })
            .previewLayout(.device)
    }
}
