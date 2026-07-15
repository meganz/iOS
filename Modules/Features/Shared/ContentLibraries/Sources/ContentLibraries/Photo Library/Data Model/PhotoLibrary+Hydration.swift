import MEGADomain

public extension PhotoLibrary {
    func replacingPhotos(from startIndex: Int, with replacements: [NodeEntity]) -> PhotoLibrary {
        guard !replacements.isEmpty, startIndex >= 0 else { return self }
        let endIndex = startIndex + replacements.count
        var flatIndex = 0

        let newYears = photoByYearList.map { year in
            PhotoByYear(categoryDate: year.categoryDate, contentList: year.contentList.map { month in
                PhotoByMonth(categoryDate: month.categoryDate, contentList: month.contentList.map { day in
                    PhotoByDay(categoryDate: day.categoryDate, contentList: day.contentList.map { node -> NodeEntity in
                        let position = flatIndex
                        flatIndex += 1
                        guard position >= startIndex, position < endIndex else { return node }
                        return replacements[position - startIndex]
                    })
                })
            })
        }
        return PhotoLibrary(photoByYearList: newYears)
    }
}
