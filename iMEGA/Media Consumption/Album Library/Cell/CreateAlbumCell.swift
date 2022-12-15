import SwiftUI

struct CreateAlbumCell: View {
    @Environment(\.colorScheme) private var colorScheme
    
    private var plusIconColor: Color {
        colorScheme == .light ? Color(Colors.General.Gray._515151.color) : Color(Colors.General.White.fcfcfc.color)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack (alignment: .center) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(Colors.General.Gray.ebebeb.color))
                
                Image(systemName: "plus")
                    .frame(width: 18)
                    .foregroundColor(plusIconColor)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(Strings.Localizable.CameraUploads.Albums.CreateAlbum.title)
                    .font(.system(size: 13.0))
                Text("")
                    .font(.system(size: 12.0))
            }
        }
    }
}
