import Foundation

final class PhotoLibraryMonthViewModel: ObservableObject {
    @Published var photosByMonthList: [PhotosByMonth]
    
    init(photosByMonthList: [PhotosByMonth]) {
        self.photosByMonthList = photosByMonthList
    }
}
