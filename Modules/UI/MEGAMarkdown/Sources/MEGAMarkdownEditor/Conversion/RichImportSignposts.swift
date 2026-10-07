import os

/// Signpost intervals for the phases of a rich import. Instruments shows them, and `XCTOSSignpostMetric` measures them.
enum RichImportSignposts {
    static let subsystem = "nz.mega.markdown"
    static let category = "RichImport"
    static let parse: StaticString = "Parse"
    static let convert: StaticString = "Convert"
    static let verify: StaticString = "Verify"

    private static let signposter = OSSignposter(subsystem: subsystem, category: category)

    static func measure<Result>(_ name: StaticString, _ work: () -> Result) -> Result {
        let state = signposter.beginInterval(name)
        defer { signposter.endInterval(name, state) }
        return work()
    }
}
