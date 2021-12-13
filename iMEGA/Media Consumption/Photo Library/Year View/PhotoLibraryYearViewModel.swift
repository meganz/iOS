import Foundation

final class PhotoLibraryYearViewModel: PhotoLibraryModeViewModel {
    @Published var photosByYearList: [PhotosByYear]
    private var libraryViewModel: PhotoLibraryContentViewModel
    
    var currentScrollPositionId: PhotoPositionId {
        if let date = libraryViewModel.currentScrollPositionId {
            return date.removeMonth()
        } else {
            return photosByYearList.last?.categoryDate
        }
    }
    
    init(libraryViewModel: PhotoLibraryContentViewModel) {
        self.libraryViewModel = libraryViewModel
        self.photosByYearList = libraryViewModel.library.photosByYearList
    }
    
    func didTapYearCard(_ photosByYear: PhotosByYear) {
        libraryViewModel.currentScrollPositionId = photosByYear.coverPhoto?.createTime
        libraryViewModel.selectedMode = .month
    }
}
