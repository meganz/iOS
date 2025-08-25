import Testing
import MEGAL10n

struct MEGAL10nTests {

    @Test func example() async throws {
        #expect(Strings.Localizable.ok == "OK")
        #expect(Strings.localized("ok", comment: "") == "OK")
    }

}
