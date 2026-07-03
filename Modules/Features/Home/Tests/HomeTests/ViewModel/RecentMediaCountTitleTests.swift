import MEGADomain
import MEGADomainMock
import MEGAL10n
import Testing
@testable import Home

@Suite("RecentMediaCountTitleTests")
struct RecentMediaCountTitleTests {
    @Test("images only uses the image count string")
    func imagesOnly() {
        #expect(
            RecentMediaCountTitleBuilder.make(imageCount: 5, videoCount: 0)
                == Strings.Localizable.Recents.Section.Thumbnail.Count.image(5)
        )
    }

    @Test("videos only uses the video count string")
    func videosOnly() {
        #expect(
            RecentMediaCountTitleBuilder.make(imageCount: 0, videoCount: 3)
                == Strings.Localizable.Recents.Section.Thumbnail.Count.video(3)
        )
    }

    @Test("mixed images and videos combines both strings")
    func mixed() {
        let expected = Strings.Localizable.Recents.Section.Thumbnail.Count.ImageAndVideo.image(5)
            + " " + Strings.Localizable.Recents.Section.Thumbnail.Count.ImageAndVideo.video(1)
        #expect(RecentMediaCountTitleBuilder.make(imageCount: 5, videoCount: 1) == expected)
    }

    @Test("classifies nodes by extension")
    func classifiesNodes() {
        let images = [node("a.jpg"), node("b.png")]
        let videos = [node("c.mp4")]

        #expect(
            RecentMediaCountTitleBuilder.make(for: images)
                == Strings.Localizable.Recents.Section.Thumbnail.Count.image(2)
        )
        #expect(
            RecentMediaCountTitleBuilder.make(for: videos)
                == Strings.Localizable.Recents.Section.Thumbnail.Count.video(1)
        )

        let expectedMixed = Strings.Localizable.Recents.Section.Thumbnail.Count.ImageAndVideo.image(2)
            + " " + Strings.Localizable.Recents.Section.Thumbnail.Count.ImageAndVideo.video(1)
        #expect(RecentMediaCountTitleBuilder.make(for: images + videos) == expectedMixed)
    }

    private func node(_ name: String) -> NodeEntity {
        NodeEntity(name: name, handle: 1)
    }
}
