import MEGAL10n

/// Creates all the data necessary to present a native share sheet for sharing a meeting link
enum ChatLinkPresentationItemSourceFactory {
    static func makeItemSource(
        title: String,
        subtitle: String,
        username: String,
        url: URL
    ) -> ChatLinkPresentationItemSource {
        .init(
            title: title + "\n" + subtitle,
            subject: Strings.Localizable.Meetings.Info.ShareMeetingLink.subject,
            message: Strings.Localizable.Meetings.Info.ShareMeetingLink.invitation(username) + "\n" +
            Strings.Localizable.Meetings.Info.ShareMeetingLink.meetingName(title) + "\n" +
            Strings.Localizable.Meetings.Info.ShareMeetingLink.meetingTime(subtitle) + "\n" +
            Strings.Localizable.Meetings.Info.ShareMeetingLink.meetingLink(url.absoluteString),
            url: url
        )
    }
}
