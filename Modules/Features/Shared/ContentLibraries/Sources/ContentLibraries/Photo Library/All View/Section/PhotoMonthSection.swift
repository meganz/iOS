import Foundation
import MEGAAppPresentation
import MEGAFoundation

final class PhotoMonthSection: PhotoDateSection {
    init(photoByMonth: PhotoByMonth) {
        let isCurrentYear = Calendar.current.component(.year, from: photoByMonth.categoryDate) == Calendar.current.component(.year, from: Date())
        let formatter: any DateFormatting = isCurrentYear ? DateFormatter.monthOnlyTemplate() : DateFormatter.monthTemplate()
        let title = formatter.localisedString(from: photoByMonth.categoryDate)
        
        let isMediaRevampEnabled = ContentLibraries.configuration.featureFlagProvider.isFeatureFlagEnabled(for: .mediaRevamp)
        let finalTitle = isMediaRevampEnabled ? title : DateFormatter.monthTemplate().localisedString(from: photoByMonth.categoryDate)

        super.init(contentList: photoByMonth.allPhotos,
                   photoByDayList: photoByMonth.contentList,
                   categoryDate: photoByMonth.categoryDate,
                   title: finalTitle)
    }
    
    override var attributedTitle: AttributedString {
        var attr = categoryDate.formatted(.dateTime.locale(.current).year().month(.wide).attributed)
        let month = AttributeContainer.dateField(.month)
        let semibold = AttributeContainer.font(.subheadline.weight(.semibold))
        attr.replaceAttributes(month, with: semibold)
        
        return attr
    }
}

extension PhotoLibrary {
    var photoMonthSections: [PhotoMonthSection] {
        photosByMonthList.map { PhotoMonthSection(photoByMonth: $0) }
    }
}
