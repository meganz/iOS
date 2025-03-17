import Foundation
import RegexBuilder

struct ReleaseNotesConverter: Converting {
    let data: Data
    let version: String?

    func toString() throws -> String {
        guard let changeLogs = String(data: data, encoding: .utf16) else {
            throw "Data is not encoded in utf16 format"
        }

        print("""
        -----------Change Logs Start:-----------
        \(changeLogs)
        -----------Change Logs End:-----------
        -----------Version Start:-----------
        \(version ?? "No version found")
        -----------Version End:-----------
        """)

        var changeLog: String?
        if let version {
            changeLog = specificChangeLog(for: version, in: changeLogs)
        }

        if changeLog == nil {
            changeLog = basicChangeLog(in: changeLogs)
        }

        print("""
        -----------Change Log Start:-----------
        \(changeLog ?? "No changeLog Found")
        -----------Change Log End:-----------
        """)

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
            formattedVersion(version)
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

    private func formattedVersion(_ version: String) -> String {
        if let match = version.firstMatch(of: /^([^\.]*\.[^\.]*)/) {
            return String(match.1)
        } else {
            return version + ".0"
        }
    }
}
