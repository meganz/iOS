import Foundation

extension MEGANodeList {
    func toPhotoLibrary(withSortType type: SortOrderType) -> PhotoLibrary {
        toNodeArray().toPhotoLibrary(withSortType: type)
    }
}

extension Array where Element == MEGANode {
    func toPhotoLibrary(withSortType type: SortOrderType) -> PhotoLibrary {
        let library = toNodeEntities().toPhotoLibrary(withSortType: type)
        return library
    }
}

extension Array where Element == NodeEntity {
    func toPhotoLibrary(withSortType type: SortOrderType) -> PhotoLibrary {
        var dayDict = [Date: PhotoByDay]()
        for node in self where NSString(string: node.name).mnz_isVisualMediaPathExtension {
            guard let day = node.categoryDate.removeTimestamp() else { continue }
            var photoByDay = dayDict[day] ?? PhotoByDay(categoryDate: day)
            photoByDay.append(node)
            dayDict[day] = photoByDay
        }
        
        var monthDict = [Date: PhotoByMonth]()
        for (day, photosByDate) in dayDict.sorted(by: { type == .oldest ? $0.key < $1.key : $0.key > $1.key }) {
            guard let month = day.removeDay() else { continue }
            var photoByMonth = monthDict[month] ?? PhotoByMonth(categoryDate: month)
            photoByMonth.append(photosByDate)
            monthDict[month] = photoByMonth
        }
        
        var yearDict = [Date: PhotoByYear]()
        for (month, photoByMonth) in monthDict.sorted(by: { type == .oldest ? $0.key < $1.key : $0.key > $1.key }) {
            guard let year = month.removeMonth() else { continue }
            var photoByYear = yearDict[year] ?? PhotoByYear(categoryDate: year)
            photoByYear.append(photoByMonth)
            yearDict[year] = photoByYear
        }
        
        return PhotoLibrary(photoByYearList: yearDict.values.sorted {
            return type == .oldest ? $0.categoryDate < $1.categoryDate : $0.categoryDate > $1.categoryDate
        })
    }
}
