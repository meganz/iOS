import Foundation

final class PhotoLibraryDayViewModel: PhotoLibraryModeViewModel {
    @Published var photosByDayList: [PhotosByDay]
    var libraryViewModel: PhotoLibraryContentViewModel
    
    var currentScrollPositionId: PhotoPositionId {
        if let date = libraryViewModel.currentScrollPositionId {
            return date.removeTimestamp()
        } else {
            return photosByDayList.last?.categoryDate
        }
    }
    
    init(libraryViewModel: PhotoLibraryContentViewModel) {
        self.libraryViewModel = libraryViewModel
        self.photosByDayList = libraryViewModel.library.allPhotosByDayList
    }
    
    func didTapDayCard(_ photoByDay: PhotosByDay) {
        libraryViewModel.currentScrollPositionId = photoByDay.coverPhoto?.createTime
        libraryViewModel.selectedMode = .all
    }
}
