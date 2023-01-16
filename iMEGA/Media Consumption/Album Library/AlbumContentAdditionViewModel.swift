import Foundation

public final class AlbumContentAdditionViewModel: ObservableObject {
    private let albumName: String
    public let locationName: String
    public var navigationTitle: String {
        "\(Strings.Localizable.CameraUploads.Albums.Create.addItemsTo) \"" + "\(albumName)" + "\""
    }
    
    @Published public var dismiss = false
    
    public init(albumName: String, locationName: String) {
        self.albumName = albumName
        self.locationName = locationName
    }
    
    public func onDone() {
        dismiss.toggle()
    }
    
    public func onFilter() {
    }
    
    public func onCancel() {
        dismiss.toggle()
    }
}
