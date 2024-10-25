import Foundation
import RegexBuilder

struct ReleaseNotesConverter: Converting {
    let data: Data
    let version: String?

    func toString() throws -> String {
        guard let changeLogs = String(data: data, encoding: .utf16) else {
            throw "Data is not encoded in utf16 format"
        }

        var changeLog: String?
        if let version {
            changeLog = specificChangeLog(for: version, in: changeLogs)
        }

        if changeLog == nil {
            changeLog = basicChangeLog(in: changeLogs)
        }

        guard let changeLog else { throw "No change log found" }
        return changeLog
    }

    private func specificChangeLog(for version: String, in changeLogs: String) -> String? {
        let regex = Regex {
            "\""
            Capture {
                OneOrMore(.any, .reluctant)
            }
            " "
            version.contains(".") ? version : "\(version).0"
            "\"=\""
            Capture {
                OneOrMore(.any, .reluctant)
            }
            "\";"
        }

        return changeLogs.firstMatch(of: regex)?.output.2.replacingOccurrences(of: "[Br]", with: "\n")
    }

    private func basicChangeLog(in changeLogs: String) -> String? {
        let regex = Regex {
            "\"Changelog basic\"=\""
            Capture {
                OneOrMore(.any, .reluctant)
            }
            "\";"
        }

        return changeLogs.firstMatch(of: regex)?.output.1.replacingOccurrences(of: "[Br]", with: "\n")
    }
}
