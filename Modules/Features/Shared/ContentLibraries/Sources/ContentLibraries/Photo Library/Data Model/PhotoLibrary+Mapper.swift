import Foundation
import MEGADomain

extension Array where Element == NodeEntity {
    /// Groups and orders the nodes into the day / month / year tree the timeline renders.
    ///
    /// - Parameter timestampBasis: which timestamp to order and bucket by. A node with no media
    ///   capture time falls back to its modification time rather than disappearing: the SDK
    ///   derives the capture time from the file name and already falls back to the modification
    ///   and creation times itself, so a missing one means no usable timestamp at all.
    public func toPhotoLibrary(
        withSortType type: SortOrderEntity,
        timestampBasis: MediaTimelineSortOrderEntity.TimestampBasis = .modificationTime,
        in timeZone: TimeZone? = nil
    ) -> PhotoLibrary {
        let timestamp: (NodeEntity) -> Date = switch timestampBasis {
        case .modificationTime: { $0.modificationTime }
        case .mediaCaptureTime: { $0.mediaCaptureTime ?? $0.modificationTime }
        }

        var photos = self
        photos.sort {
            if timestamp($0) == timestamp($1) {
                return $0.handle > $1.handle
            } else {
                return type == .modificationAsc ? timestamp($0) < timestamp($1) : timestamp($0) > timestamp($1)
            }
        }
        
        var tempDayDict = [Date: PhotoByDayDataProvider]()
        for node in photos where node.fileExtensionGroup.isVisualMedia {
            guard let day = timestamp(node).removeTimestamp(timeZone: timeZone) else { continue }
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
        for (day, photosByDay) in dayDict.sorted(by: { type == .modificationAsc ? $0.key < $1.key : $0.key > $1.key }) {
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
        for (month, photoByMonth) in monthDict.sorted(by: { type == .modificationAsc ? $0.key < $1.key : $0.key > $1.key }) {
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
            return type == .modificationAsc ? $0.categoryDate < $1.categoryDate : $0.categoryDate > $1.categoryDate
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
