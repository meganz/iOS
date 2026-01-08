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

        guard let changeLog else {
            throw """
                ----------START-------------
                No change log found in 
                
                \(changeLogs)
                
                for version 
                
                \(version ?? "no version passed")
                ----------END-------------
                """
        }
        return changeLog
    }

    private func specificChangeLog(for version: String, in changeLogs: String) -> String? {
        let regex = Regex {
            "\""
            OneOrMore(.any, .reluctant)
            formattedVersion(version)
            "\""
            ZeroOrMore(.whitespace)
            "="
            ZeroOrMore(.whitespace)
            "\""
            Capture {
                OneOrMore(.any, .reluctant)
            }
            "\";"
        }

        return changeLogs.firstMatch(of: regex).map {
            String($0.output.1).replacingOccurrences(of: "[Br]", with: "\n")
        }
    }

    private func basicChangeLog(in changeLogs: String) -> String? {
        let regex = Regex {
            "\"Changelog basic\""
            ZeroOrMore(.whitespace)
            "="
            ZeroOrMore(.whitespace)
            "\""
            Capture {
                OneOrMore(.any, .reluctant)
            }
            "\";"
        }

        return changeLogs.firstMatch(of: regex).map {
            String($0.output.1).replacingOccurrences(of: "[Br]", with: "\n")
        }
    }

    private func formattedVersion(_ version: String) -> String {
        if let match = version.firstMatch(of: /^([^\.]*\.[^\.]*)/) {
            return String(match.1)
        } else {
            return version + ".0"
        }
    }
}
