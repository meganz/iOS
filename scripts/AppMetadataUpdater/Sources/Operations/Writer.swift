import Foundation

struct Writer {
    let folders: [String]
    let languageName: String
    let string: String
    let fileName: String
    private let basePath = "../../fastlane/metadata/"

    func write() throws {
        for folder in folders {
            let path = basePath.appending(folder).appending("/\(fileName)")

            if FileManager.default.fileExists(atPath: path) {
                do {
                    try string.write(toFile: path, atomically: true, encoding: .utf8)
                    printToConsole(path: path, string: string)
                } catch {
                    throw "Failed to write to file at path: \(path), error: \(error)"
                }
            } else {
                throw "File does not exist at path: \(path)"
            }
        }
    }

    private func printToConsole(path: String, string: String) {
        let printString = """
                ------------------\(languageName) Start -----------------
                File exists at path: \(path), saved with \n\(string)
                ------------------\(languageName) End -----------------
                """
        print(printString)
    }
}
