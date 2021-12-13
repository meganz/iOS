import Foundation

final class PhotoLibraryMonthViewModel: PhotoLibraryModeViewModel {
    @Published var photosByMonthList: [PhotosByMonth]
    private var libraryViewModel: PhotoLibraryContentViewModel
    
    var currentScrollPositionId: PhotoPositionId {
        if let date = libraryViewModel.currentScrollPositionId {
            return date.removeDay()
        } else {
            return photosByMonthList.last?.categoryDate
        }
    }
    
    init(libraryViewModel: PhotoLibraryContentViewModel) {
        self.libraryViewModel = libraryViewModel
        self.photosByMonthList = libraryViewModel.library.allPhotosByMonthList
    }
    
    func didTapMonthCard(_ photoByMonth: PhotosByMonth) {
        libraryViewModel.currentScrollPositionId = photoByMonth.coverPhoto?.createTime
        libraryViewModel.selectedMode = .day
    }
}
