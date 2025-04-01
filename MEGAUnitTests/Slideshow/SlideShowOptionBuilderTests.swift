@testable import MEGA
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGAL10n
import XCTest

final class SlideShowOptionBuilderTests: XCTestCase {

    private func makeSlideShowOptionsCellVM(
        name: SlideShowOptionName = .speed
    ) -> SlideShowOptionCellViewModel {
        SlideShowOptionCellViewModel(
            name: name,
            title: Strings.Localizable.Slideshow.PreferenceSetting.speed,
            type: .detail, children: [
                SlideShowOptionDetailCellViewModel(
                    name: .speedNormal,
                    title: Strings.Localizable.Slideshow.PreferenceSetting.Speed.slow,
                    isSelected: false
                )
            ],
            tracker: MockTracker())
    }

    private func makeSlideShowOptionDetailCellVM(
        name: SlideShowOptionName = .speed
    ) -> SlideShowOptionDetailCellViewModel {
        SlideShowOptionDetailCellViewModel(
            name: name,
            title: Strings.Localizable.Slideshow.PreferenceSetting.speed,
            isSelected: false
        )
    }

    func testSlideShowOptionBuilder_populate_shouldNotBeEmpty() {
        let slideShowOption1 = makeSlideShowOptionsCellVM()
        let slideShowOption2 = makeSlideShowOptionsCellVM(name: .order)
        let slideShowOption3 = makeSlideShowOptionsCellVM(name: .orderOldest)

        @SlideShowOptionBuilder var actualSlideShowOptions: [SlideShowOptionCellViewModel] {
            slideShowOption1
            slideShowOption2
            slideShowOption3
        }

        XCTAssertTrue(actualSlideShowOptions.isNotEmpty, "SlideShowOptionBuilder did not correctly build the options array as it should not be empty")
    }

    func testSlideShowOptionBuilder_populate_expectedShouldBeSameWithActual() {
        let slideShowOption1 = makeSlideShowOptionsCellVM()
        let slideShowOption2 = makeSlideShowOptionsCellVM(name: .order)
        let slideShowOption3 = makeSlideShowOptionsCellVM(name: .orderOldest)

        let expectedSlideShowOptions = [slideShowOption1, slideShowOption2, slideShowOption3]

        @SlideShowOptionBuilder var actualSlideShowOptions: [SlideShowOptionCellViewModel] {
            slideShowOption1
            slideShowOption2
            slideShowOption3
        }

        XCTAssertEqual(
            actualSlideShowOptions.map { $0.id },
            expectedSlideShowOptions.map { $0.id },
            "SlideShowOptionBuilder did not correctly build the options array as ids should be same with expected"
        )
    }

    func testSlideShowOptionChildrenBuilder_populate_shouldNotBeEmpty() {
        let slideShowDetailOption1 = makeSlideShowOptionDetailCellVM()
        let slideShowDetailOption2 = makeSlideShowOptionDetailCellVM(name: .order)
        let slideShowDetailOption3 = makeSlideShowOptionDetailCellVM(name: .orderOldest)

        @SlideShowOptionChildrenBuilder var actualSlideShowDetailOptions: [SlideShowOptionDetailCellViewModel] {
            slideShowDetailOption1
            slideShowDetailOption2
            slideShowDetailOption3
        }

        XCTAssertTrue(actualSlideShowDetailOptions.isNotEmpty, "SlideShowOptionChildrenBuilder did not correctly build the options array as it should not be empty")
    }

    func testSlideShowOptionChildrenBuilder_populate_expectedOrderShouldBeSameWithActualOrder() {
        let slideShowDetailOption1 = makeSlideShowOptionDetailCellVM()
        let slideShowDetailOption2 = makeSlideShowOptionDetailCellVM(name: .order)
        let slideShowDetailOption3 = makeSlideShowOptionDetailCellVM(name: .orderOldest)

        let expectedSlideShowDetailOptions = [slideShowDetailOption1, slideShowDetailOption2, slideShowDetailOption3]

        @SlideShowOptionChildrenBuilder var actualSlideShowDetailOptions: [SlideShowOptionDetailCellViewModel] {
            slideShowDetailOption1
            slideShowDetailOption2
            slideShowDetailOption3
        }

        XCTAssertEqual(
            expectedSlideShowDetailOptions.map { $0.id },
            actualSlideShowDetailOptions.map { $0.id },
            "SlideShowOptionChildrenBuilder did not correctly build the options array as ids should be same with expected"
        )
    }
}
