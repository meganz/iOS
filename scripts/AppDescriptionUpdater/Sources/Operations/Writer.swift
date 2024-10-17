import Foundation

struct Writer {
    let folders: [String]
    let languageName: String
    private let basePath = "../../fastlane/metadata/"
    private let descriptionFileName = "description.txt"

    func write(_ latestDescription: String) throws {
        for folder in folders {
            let path = basePath.appending(folder).appending("/\(descriptionFileName)")

            if FileManager.default.fileExists(atPath: path) {
                do {
                    try latestDescription.write(toFile: path, atomically: true, encoding: .utf8)
                    printToConsole(path: path, latestDescription: latestDescription)
                } catch {
                    throw "Failed to write to file at path: \(path), error: \(error)"
                }
            } else {
                throw "File does not exist at path: \(path)"
            }
        }
    }

    private func printToConsole(path: String, latestDescription: String) {
        let printString = """
                ------------------\(languageName) Start -----------------
                File exists at path: \(path), saved with \n\(latestDescription)
                ------------------\(languageName) End -----------------
                """
        print(printString)
    }
}
