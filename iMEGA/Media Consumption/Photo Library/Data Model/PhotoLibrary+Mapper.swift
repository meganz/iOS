import Foundation
import MEGADomain

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
    func toPhotoLibrary(withSortType type: SortOrderType, in timeZone: TimeZone? = nil) -> PhotoLibrary {
        var tempDayDict = [Date: PhotoByDayDataProvider]()
        for node in self where NSString(string: node.name).mnz_isVisualMediaPathExtension {
            guard let day = node.categoryDate.removeTimestamp(timeZone: timeZone) else { continue }
            if let photoByDay = tempDayDict[day] {
                photoByDay.photos.append(node)
            } else {
                let photoByDay = PhotoByDayDataProvider(categoryDate: day)
                photoByDay.photos.append(node)
                tempDayDict[day] = photoByDay
            }
        }
        let dayDict = tempDayDict.mapValues { $0.toPhotoByDay() }
        
        var tempMonthDict = [Date: PhotoByMonthDataProvider]()
        for (day, photosByDay) in dayDict.sorted(by: { type == .oldest ? $0.key < $1.key : $0.key > $1.key }) {
            guard let month = day.removeDay(timeZone: timeZone) else { continue }
            if let photoByMonth = tempMonthDict[month] {
                photoByMonth.photos.append(photosByDay)
            } else {
                let photoByMonth = PhotoByMonthDataProvider(categoryDate: month)
                photoByMonth.photos.append(photosByDay)
                tempMonthDict[month] = photoByMonth
            }
        }
        let monthDict = tempMonthDict.mapValues { $0.toPhotoByMonth() }
        
        var tempYearDict = [Date: PhotoByYearDataProvider]()
        for (month, photoByMonth) in monthDict.sorted(by: { type == .oldest ? $0.key < $1.key : $0.key > $1.key }) {
            guard let year = month.removeMonth(timeZone: timeZone) else { continue }
            if let photoByYear = tempYearDict[year] {
                photoByYear.photos.append(photoByMonth)
            } else {
                let photoByYear = PhotoByYearDataProvider(categoryDate: year)
                photoByYear.photos.append(photoByMonth)
                tempYearDict[year] = photoByYear
            }
        }
        let yearDict = tempYearDict.mapValues { $0.toPhotoByYear() }
        
        return PhotoLibrary(photoByYearList: yearDict.values.sorted {
            return type == .oldest ? $0.categoryDate < $1.categoryDate : $0.categoryDate > $1.categoryDate
        })
    }
}

private class PhotoDataProvider {
    let categoryDate: Date
    
    init(categoryDate: Date) {
        self.categoryDate = categoryDate
    }
}

private final class PhotoByDayDataProvider: PhotoDataProvider {
    var photos = [NodeEntity]()
    
    func toPhotoByDay() -> PhotoByDay {
        PhotoByDay(categoryDate: categoryDate, contentList: photos)
    }
}

private final class PhotoByMonthDataProvider: PhotoDataProvider {
    var photos = [PhotoByDay]()
    
    func toPhotoByMonth() -> PhotoByMonth {
        PhotoByMonth(categoryDate: categoryDate, contentList: photos)
    }
}

private final class PhotoByYearDataProvider: PhotoDataProvider {
    var photos = [PhotoByMonth]()
    
    func toPhotoByYear() -> PhotoByYear {
        PhotoByYear(categoryDate: categoryDate, contentList: photos)
    }
}
