import Foundation
import PinLayout
import SwiftUI

final class PhotoLibrary {
    var photosByYearList: [PhotosByYear]
    
    var allPhotosByMonthList: [PhotosByMonth] {
        photosByYearList.flatMap { $0.photosByMonthList }
    }
    
    var allPhotosByDayList: [PhotosByDay] {
        allPhotosByMonthList.flatMap { $0.photosByDayList }
    }
    
    var allPhotos: [NodeEntity] {
        allPhotosByDayList.flatMap { $0.photoNodeList }
    }
    
    init(photosByYearList: [PhotosByYear]) {
        self.photosByYearList = photosByYearList
    }
}

final class PhotosByYear: Identifiable {
    let year: Date
    var photosByMonthList = [PhotosByMonth]()
    
    var coverPhoto: NodeEntity? {
        photosByMonthList.last?.coverPhoto
    }
    
    init(year: Date) {
        self.year = year
    }
}

final class PhotosByMonth: Identifiable {
    let month: Date
    var photosByDayList = [PhotosByDay]()
    
    var allPhotos: [NodeEntity] {
        photosByDayList.flatMap { $0.photoNodeList }
    }
    
    var coverPhoto: NodeEntity? {
        photosByDayList.last?.coverPhoto
    }
    
    init(month: Date) {
        self.month = month
    }
}

final class PhotosByDay: Identifiable {
    let day: Date
    var photoNodeList = [NodeEntity]()
    
    var coverPhoto: NodeEntity? {
        photoNodeList.last
    }
    
    init(day: Date) {
        self.day = day
    }
}

extension MEGANodeList {
    func toPhotoLibrary() -> PhotoLibrary {
        toNodeEntities().toPhotoLibrary()
    }
}

extension Array where Element == NodeEntity {
    func toPhotoLibrary() -> PhotoLibrary {
        var dayDict = [Date: PhotosByDay]()
        for node in self where NSString(string: node.name).mnz_isVisualMediaPathExtension {
            guard let day = (node.createTime ?? Date()).removeTimestamp() else { continue }
            let photosByDay = dayDict[day] ?? PhotosByDay(day: day)
            photosByDay.photoNodeList.append(node)
            dayDict[day] = photosByDay
        }
        
        var monthDict = [Date: PhotosByMonth]()
        for (day, photosByDate) in dayDict.sorted(by: { $0.key < $1.key }) {
            guard let month = day.removeDay() else { continue }
            let photosByMonth = monthDict[month] ?? PhotosByMonth(month: month)
            photosByMonth.photosByDayList.append(photosByDate)
            monthDict[month] = photosByMonth
        }
        
        var yearDict = [Date: PhotosByYear]()
        for (month, photosByMonth) in monthDict.sorted(by: { $0.key < $1.key }) {
            guard let year = month.removeMonth() else { continue }
            let photosByYear = yearDict[year] ?? PhotosByYear(year: year)
            photosByYear.photosByMonthList.append(photosByMonth)
            yearDict[year] = photosByYear
        }
        
        return PhotoLibrary(photosByYearList: yearDict.values.sorted(by: { $0.year < $1.year }))
    }
}
