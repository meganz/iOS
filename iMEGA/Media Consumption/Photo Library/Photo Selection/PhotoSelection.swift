import Foundation
import Combine
import SwiftUI

final class PhotoSelection: ObservableObject {
    @Published var editMode: EditMode = .inactive {
        willSet {
            if !newValue.isEditing {
                allSelected = false
            }
        }
    }
    
    @Published var photos = [MEGAHandle: NodeEntity]()
    
    @Published var allSelected = false {
        willSet {
            if !newValue {
                photos.removeAll()
            }
        }
    }
    
    func setSelectedPhotos(_ photos: [NodeEntity]) {
        self.photos = Dictionary(uniqueKeysWithValues: photos.map { ($0.handle, $0) })
    }
    
    func isPhotoSelected(_ photo: NodeEntity) -> Bool {
        photos[photo.handle] != nil
    }
}
