import Foundation

final class AlbumContentAdditionViewModel: ObservableObject {
    private let albumName: String
    let locationName: String
    var navigationTitle: String {
        "\(Strings.Localizable.CameraUploads.Albums.Create.addItemsTo) \"" + "\(albumName)" + "\""
    }
    
    @Published public var dismiss = false
    
    init(albumName: String, locationName: String) {
        self.albumName = albumName
        self.locationName = locationName
    }
    
    func onDone() {
        dismiss.toggle()
    }
    
    func onFilter() {
    }
    
    func onCancel() {
        dismiss.toggle()
    }
}
