import Foundation

extension MEGANodeList {
    func toPhotoLibrary() -> PhotoLibrary {
        let library = toNodeEntities().toPhotoLibrary()
        library.underlyingMEGANodes = toNodeArray()
        return library
    }
}

extension Array where Element == NodeEntity {
    func toPhotoLibrary() -> PhotoLibrary {
        var dayDict = [Date: PhotosByDay]()
        for node in self {
            guard let day = node.categoryDate.removeTimestamp() else { continue }
            let photosByDay = dayDict[day] ?? PhotosByDay(categoryDate: day)
            photosByDay.photoNodeList.append(node)
            dayDict[day] = photosByDay
        }
        
        var monthDict = [Date: PhotosByMonth]()
        for (day, photosByDate) in dayDict.sorted(by: { $0.key < $1.key }) {
            guard let month = day.removeDay() else { continue }
            let photosByMonth = monthDict[month] ?? PhotosByMonth(categoryDate: month)
            photosByMonth.photosByDayList.append(photosByDate)
            monthDict[month] = photosByMonth
        }
        
        var yearDict = [Date: PhotosByYear]()
        for (month, photosByMonth) in monthDict.sorted(by: { $0.key < $1.key }) {
            guard let year = month.removeMonth() else { continue }
            let photosByYear = yearDict[year] ?? PhotosByYear(categoryDate: year)
            photosByYear.photosByMonthList.append(photosByMonth)
            yearDict[year] = photosByYear
        }
        
        return PhotoLibrary(photosByYearList: yearDict.values.sorted(by: { $0.categoryDate < $1.categoryDate }))
    }
}
