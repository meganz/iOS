import Foundation

extension MEGANodeList {
    func toPhotoLibrary() -> PhotoLibrary {
        toNodeArray().toPhotoLibrary()
    }
}

extension Array where Element == MEGANode {
    func toPhotoLibrary() -> PhotoLibrary {
        let library = map { $0.toNodeEntity() }.toPhotoLibrary()
        return library
    }
}

extension Array where Element == NodeEntity {
    func toPhotoLibrary() -> PhotoLibrary {
        let megaNodes = toMEGANodes()
        
        var dayDict = [Date: PhotoByDay]()
        for node in self where NSString(string: node.name).mnz_isVisualMediaPathExtension {
            guard let day = node.categoryDate.removeTimestamp() else { continue }
            var photoByDay = dayDict[day] ?? PhotoByDay(categoryDate: day)
            photoByDay.append(node)
            dayDict[day] = photoByDay
        }
        
        var monthDict = [Date: PhotoByMonth]()
        for (day, photosByDate) in dayDict.sorted(by: { $0.key > $1.key }) {
            guard let month = day.removeDay() else { continue }
            var photoByMonth = monthDict[month] ?? PhotoByMonth(categoryDate: month)
            photoByMonth.append(photosByDate)
            monthDict[month] = photoByMonth
        }
        
        var yearDict = [Date: PhotoByYear]()
        for (month, photoByMonth) in monthDict.sorted(by: { $0.key > $1.key }) {
            guard let year = month.removeMonth() else { continue }
            var photoByYear = yearDict[year] ?? PhotoByYear(categoryDate: year)
            photoByYear.append(photoByMonth)
            yearDict[year] = photoByYear
        }
        
        var library = PhotoLibrary(photoByYearList: yearDict.values.sorted(by: { $0.categoryDate > $1.categoryDate }))
        library.underlyingMEGANodes = megaNodes
        
        return library
    }
    
    func toMEGANodes() -> [MEGANode] {
        compactMap { $0.toMEGANode(in: MEGASdkManager.sharedMEGASdk()) }
    }
}
