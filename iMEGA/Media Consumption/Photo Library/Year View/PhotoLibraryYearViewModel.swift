import Foundation

final class PhotoLibraryYearViewModel: ObservableObject {
    @Published var photosByYearList: [PhotosByYear]
    
    init(photosByYearList: [PhotosByYear]) {
        self.photosByYearList = photosByYearList
    }
}
