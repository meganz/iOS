import Foundation
import Combine
import SwiftUI
import MEGADomain

final class PhotoSelection: ObservableObject {
    private let selectLimit: Int?
    
    init(selectLimit: Int? = nil) {
        self.selectLimit = selectLimit
    }
    
    var isSelectionLimitReachedPublisher: AnyPublisher<Bool, Never>? {
        guard let selectLimit else {
            return nil
        }
        return $photos
            .map { $0.count >= selectLimit }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    @Published var editMode: EditMode = .inactive {
        willSet {
            if !newValue.isEditing {
                allSelected = false
            }
        }
    }
    
    @Published var photos = [HandleEntity: NodeEntity]()
    
    @Published var allSelected = false {
        willSet {
            if !newValue {
                photos.removeAll()
            }
        }
    }
    
    @Published var isItemSelectedAfterLimitReached = false
    
    func setSelectedPhotos(_ photos: [NodeEntity]) {
        self.photos = Dictionary(uniqueKeysWithValues: photos.map { ($0.handle, $0) })
    }
    
    func isPhotoSelected(_ photo: NodeEntity) -> Bool {
        photos[photo.handle] != nil
    }
}
