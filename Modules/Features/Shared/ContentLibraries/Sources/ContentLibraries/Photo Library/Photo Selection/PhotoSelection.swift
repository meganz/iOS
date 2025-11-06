import Combine
import Foundation
import MEGADomain
import SwiftUI

public final class PhotoSelection: ObservableObject {
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
    
    @Published public var editMode: EditMode = .inactive {
        willSet {
            if !newValue.isEditing {
                allSelected = false
            }
        }
    }
    
    @Published public var photos = [HandleEntity: NodeEntity]()
    
    @Published public var allSelected = false {
        willSet {
            if !newValue {
                photos.removeAll()
            }
        }
    }
    
    @Published public var isItemSelectedAfterLimitReached = false
    
    @Published public var isHidden = false
    
    @Published var isSelectionDisabled = false
    
    public func setSelectedPhotos(_ photos: [NodeEntity]) {
        self.photos = Dictionary(uniqueKeysWithValues: photos.map { ($0.handle, $0) })
    }
    
    func isPhotoSelected(_ photo: NodeEntity) -> Bool {
        photos[photo.handle] != nil
    }
}
