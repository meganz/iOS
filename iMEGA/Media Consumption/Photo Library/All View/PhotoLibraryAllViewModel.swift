import SwiftUI

@available(iOS 14.0, *)
final class PhotoLibraryAllViewModel: PhotoLibraryModeViewModel<PhotoDateSection> {
    private var lastCardPosition: PhotoScrollPosition?
    private var lastPhotoPosition: PhotoScrollPosition?
    
    @Published var zoomState = PhotoLibraryZoomState() {
        willSet {
            zoomStateWillChange(to: newValue)
        }
    }
    
    @Published var selectedNode: NodeEntity?
    @Published var columns: [GridItem] = Array(
        repeating: .init(.flexible(), spacing: 4),
        count: PhotoLibraryZoomState.defaultScaleFactor
    )
    
    override var position: PhotoScrollPosition? {
        calculateCurrentScrollPosition()
    }
    
    override init(libraryViewModel: PhotoLibraryContentViewModel) {
        super.init(libraryViewModel: libraryViewModel)
        
        photoCategoryList = libraryViewModel.library.allPhotosMonthSections
        
        subscribeToLibraryChange()
        subscribeToSelectedModeChange()
    }
    
    // MARK: Private
    
    private func subscribeToLibraryChange() {
        libraryViewModel
            .$library
            .dropFirst()
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .map { [weak self] in
                $0.allPhotosDateSections(forZoomScaleFactor: self?.zoomState.scaleFactor)
            }
            .filter { [weak self] in
                self?.shouldRefreshTo($0) == true
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$photoCategoryList)
    }
    
    private func shouldRefreshTo(_ categories: [PhotoDateSection]) -> Bool {
        photoCategoryList.flatMap {
            $0.contentList
        }
        .shouldRefreshTo(
            categories.flatMap {
                $0.contentList
            },
            forVisiblePositions: scrollTracker.visiblePositions)
    }
    
    private func subscribeToSelectedModeChange() {
        libraryViewModel
            .$selectedMode
            .dropFirst()
            .combinePrevious(.all)
            .filter {
                $0.previous == .all
            }
            .sink { [weak self] _ in
                self?.calculateLastScrollPosition()
            }
            .store(in: &subscriptions)
    }
    
    private func zoomStateWillChange(to newState: PhotoLibraryZoomState) {
        photoCategoryList = libraryViewModel.library.allPhotosDateSections(forZoomScaleFactor: newState.scaleFactor)
        
        calculateLastScrollPosition()
        
        columns = Array(
            repeating: .init(.flexible(), spacing: 4),
            count: newState.scaleFactor)
    }
}

// MARK: - Scroll Position Management
@available(iOS 14.0, *)
extension PhotoLibraryAllViewModel {
    func hasPositionChange() -> Bool {
        libraryViewModel.cardScrollPosition != lastCardPosition ||
        libraryViewModel.photoScrollPosition != lastPhotoPosition
    }
    
    private func calculateCurrentScrollPosition() -> PhotoScrollPosition? {
        func calculate() -> PhotoScrollPosition? {
            guard let photoPosition = libraryViewModel.photoScrollPosition else {
                MEGALogDebug("[Photos] all position - uses card position \(String(describing: libraryViewModel.cardScrollPosition?.date))")
                return libraryViewModel.cardScrollPosition
            }
            
            guard let cardPosition = libraryViewModel.cardScrollPosition else {
                MEGALogDebug("[Photos] all position - uses photo position \(String(describing: photoPosition.date))")
                return photoPosition
            }
            
            let photoByDayList: [PhotoByDay] = photoCategoryList.flatMap {
                $0.photoByDayList
            }
            
            guard let dayCategory = photoByDayList.first(where: { $0.categoryDate == cardPosition.date.removeTimestamp() }) else {
                MEGALogDebug("[Photos] all position - can not find day category by card \(String(describing: cardPosition.date))")
                return cardPosition
            }
            
            guard dayCategory.contentList.first(where: { $0.handle == photoPosition.handle }) != nil else {
                MEGALogDebug("[Photos] all position - photo position \(String(describing: photoPosition.date)) is not in card: \(String(describing: cardPosition.date))")
                return cardPosition
            }
            
            MEGALogDebug("[Photos] all position - card contains photo position \(String(describing: photoPosition.date))")
            return photoPosition
        }
        
        if let position = calculate(), position != .top {
            return position
        } else {
            // Scroll to top which is the first photo
            return photoCategoryList.first?.contentList.first?.position
        }
    }
    
    private func calculateLastScrollPosition() {
        let previousPhotoPosition = libraryViewModel.photoScrollPosition
        scrollTracker.calculateScrollPosition(&libraryViewModel.photoScrollPosition)
        
        if previousPhotoPosition != libraryViewModel.photoScrollPosition {
            // Clear card scroll position when photo scroll position changes
            libraryViewModel.cardScrollPosition = nil
        }
        
        if libraryViewModel.photoScrollPosition == .top {
            // Clear both card and photo positions when it scrolls to top
            libraryViewModel.cardScrollPosition = nil
            libraryViewModel.photoScrollPosition = nil
        }
        
        lastCardPosition = libraryViewModel.cardScrollPosition
        lastPhotoPosition = libraryViewModel.photoScrollPosition
        
        MEGALogDebug("[Photos] all after calculation card:\(String(describing: libraryViewModel.cardScrollPosition?.date)), photo: \(String(describing: libraryViewModel.photoScrollPosition?.date))")
    }
}
