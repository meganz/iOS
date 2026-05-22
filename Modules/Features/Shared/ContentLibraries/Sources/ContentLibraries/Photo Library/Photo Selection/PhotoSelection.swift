import Combine
import Foundation
import MEGADomain
import SwiftUI

public final class PhotoSelection: ObservableObject {
    private let selectLimit: Int?
    
    private static let recentLongPressWindow: TimeInterval = 0.7
    private var recentLongPressHandle: HandleEntity?
    private var recentLongPressAt: Date?

    init(selectLimit: Int? = nil) {
        self.selectLimit = selectLimit
    }

    /// Records that `handle` was just added to the selection by a long-press gesture.
    /// `wasRecentlyLongPressed(_:)` returns true for that handle until the window expires
    /// or another action consumes the mark — used to keep drag-select from immediately
    /// deselecting the long-pressed item when the user keeps the finger down and drags.
    public func markRecentlyLongPressed(_ handle: HandleEntity) {
        recentLongPressHandle = handle
        recentLongPressAt = Date()
    }

    public func wasRecentlyLongPressed(_ handle: HandleEntity) -> Bool {
        guard recentLongPressHandle == handle,
              let at = recentLongPressAt,
              Date().timeIntervalSince(at) < Self.recentLongPressWindow
        else { return false }
        return true
    }

    public func consumeRecentLongPressMark() {
        recentLongPressHandle = nil
        recentLongPressAt = nil
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
    
    public func toggleEditMode() {
        editMode = editMode.isEditing ? .inactive : .active
    }
    
    func isPhotoSelected(_ photo: NodeEntity) -> Bool {
        photos[photo.handle] != nil
    }
    
    public func selectPhoto(_ photo: NodeEntity) {
        if let selectLimit = selectLimit, photos.count >= selectLimit {
            isItemSelectedAfterLimitReached = true
            return
        }
        photos[photo.handle] = photo
    }
    
    public func deselectPhoto(_ photo: NodeEntity) {
        photos.removeValue(forKey: photo.handle)
    }
    
    public func clear() {
        photos.removeAll()
    }
}
