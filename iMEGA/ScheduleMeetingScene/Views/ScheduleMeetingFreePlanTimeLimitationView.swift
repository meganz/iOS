import MEGADesignToken
import MEGAL10n
import SwiftUI

struct ScheduleMeetingFreePlanTimeLimitationView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let action: (() -> Void)

    var body: some View {
        VStack(spacing: 0) {
            Text(createAttributedStringForAccentTags(content: Strings.Localizable.Meetings.ScheduleMeeting.Create.FreePlanLimitWarning.longerThan60Minutes))
                .font(.footnote)
                .foregroundStyle(isDesignTokenEnabled
                                 ? TokenColors.Text.primary.swiftUI
                                 : colorScheme == .dark ? MEGAAppColor.White._FFFFFF.color : MEGAAppColor.Black._000000.color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 6)
                .padding(.bottom, 20)
        }
        .frame(minHeight: 53.0)
        .background(isDesignTokenEnabled
                    ? TokenColors.Background.page.swiftUI
                    : colorScheme == .dark ? MEGAAppColor.Black._000000.color : MEGAAppColor.White._F7F7F7.color)
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }
    
    private func createAttributedStringForAccentTags(content: String) -> AttributedString {
        var attributedString = AttributedString(content)

        guard let rangeStart = attributedString.range(of: "[A]"),
           let rangeEnd = attributedString.range(of: "[/A]", options: .backwards),
              rangeEnd.lowerBound > rangeStart.upperBound else {
            return attributedString
        }
        let startIndex = attributedString.index(rangeStart.upperBound, offsetByCharacters: 0)
        let endIndex = attributedString.index(rangeEnd.lowerBound, offsetByCharacters: 0)
        let substringRange = startIndex..<endIndex
        attributedString[substringRange].foregroundColor = isDesignTokenEnabled
        ? TokenColors.Support.success.swiftUI
        : MEGAAppColor.Green._00A886.color
        
        attributedString.removeSubrange(rangeEnd)
        attributedString.removeSubrange(rangeStart)

        return attributedString
    }
}
