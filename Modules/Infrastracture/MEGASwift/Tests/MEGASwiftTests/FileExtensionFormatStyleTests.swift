@testable import MEGASwift
import XCTest

@available(iOS 15.0, *)
final class FileExtensionFormatStyleTests: XCTestCase {
    // MARK: - Capitalization -
    
    // MARK: File Name Set, PathExtension is `.verbatim`
    
    func testFormatFilePath_withLowercaseStrategy() throws {
        let input: FileExtension = "FiLeNaMe.TxT"
        let resultFrom = (
            fileExtensionTwoInits: input.formatted(
                .filePath(name: .component(capitalization: .lowercased))
            ),
            fileExtensionBuildThenInit: input.formatted(
                .filePath().name(capitalization: .lowercased)
            ),
            fileExtensionInitThenBuild: input.formatted(
                .filePath(name: .component().capitalization(.lowercased))
            )
        )
        XCTAssertTrue(Set([
            resultFrom.fileExtensionTwoInits,
            resultFrom.fileExtensionBuildThenInit,
            resultFrom.fileExtensionInitThenBuild
        ]).count == 1, "All format styles should return the same result")
        XCTAssertEqual(resultFrom.fileExtensionTwoInits, "filename.TxT")
        XCTAssertEqual(resultFrom.fileExtensionBuildThenInit, "filename.TxT")
        XCTAssertEqual(resultFrom.fileExtensionInitThenBuild, "filename.TxT")
    }
    
    func testFormatFilePath_withUppercaseStrategy() throws {
        let input: FileExtension = "FiLeNaMe.TxT"
        let resultFrom = (
            fileExtensionTwoInits: input.formatted(
                .filePath(name: .component(capitalization: .uppercase))
            ),
            fileExtensionBuildThenInit: input.formatted(
                .filePath().name(capitalization: .uppercase)
            ),
            fileExtensionInitThenBuild: input.formatted(
                .filePath(name: .component().capitalization(.uppercase))
            )
        )
        XCTAssertTrue(Set([
            resultFrom.fileExtensionTwoInits,
            resultFrom.fileExtensionBuildThenInit,
            resultFrom.fileExtensionInitThenBuild
        ]).count == 1, "All format styles should return the same result")
        XCTAssertEqual(resultFrom.fileExtensionTwoInits, "FILENAME.TxT")
        XCTAssertEqual(resultFrom.fileExtensionBuildThenInit, "FILENAME.TxT")
        XCTAssertEqual(resultFrom.fileExtensionInitThenBuild, "FILENAME.TxT")
    }
    
    func testFormatFilePath_withCapitalizedStrategy() throws {
        let input: FileExtension = "FiLeNaMe.TxT"
        let resultFrom = (
            fileExtensionTwoInits: input.formatted(
                .filePath(name: .component(capitalization: .capitalized))
            ),
            fileExtensionBuildThenInit: input.formatted(
                .filePath().name(capitalization: .capitalized)
            ),
            fileExtensionInitThenBuild: input.formatted(
                .filePath(name: .component().capitalization(.capitalized))
            )
        )
        XCTAssertTrue(Set([
            resultFrom.fileExtensionTwoInits,
            resultFrom.fileExtensionBuildThenInit,
            resultFrom.fileExtensionInitThenBuild
        ]).count == 1, "All format styles should return the same result")
        XCTAssertEqual(resultFrom.fileExtensionTwoInits, "Filename.TxT")
        XCTAssertEqual(resultFrom.fileExtensionBuildThenInit, "Filename.TxT")
        XCTAssertEqual(resultFrom.fileExtensionInitThenBuild, "Filename.TxT")
    }
    
    func testFormatFilePath_withCapitalizedStrategyAndSpace() throws {
        let input: FileExtension = "FiLe nAmE.TxT"
        let resultFrom = (
            fileExtensionTwoInits: input.formatted(
                .filePath(name: .component(capitalization: .capitalized))
            ),
            fileExtensionBuildThenInit: input.formatted(
                .filePath().name(capitalization: .capitalized)
            ),
            fileExtensionInitThenBuild: input.formatted(
                .filePath(name: .component().capitalization(.capitalized))
            )
        )
        XCTAssertTrue(Set([
            resultFrom.fileExtensionTwoInits,
            resultFrom.fileExtensionBuildThenInit,
            resultFrom.fileExtensionInitThenBuild
        ]).count == 1, "All format styles should return the same result")
        XCTAssertEqual(resultFrom.fileExtensionTwoInits, "File Name.TxT")
        XCTAssertEqual(resultFrom.fileExtensionBuildThenInit, "File Name.TxT")
        XCTAssertEqual(resultFrom.fileExtensionInitThenBuild, "File Name.TxT")
    }
    
    func testFormatFilePath_withExplicitVerbatimStrategy() throws {
        let input: FileExtension = "FiLeNaMe.TxT"
        let resultFrom = (
            fileExtensionTwoInits: input.formatted(
                .filePath(name: .component(capitalization: .verbatim))
            ),
            fileExtensionBuildThenInit: input.formatted(
                .filePath().name(capitalization: .verbatim)
            ),
            fileExtensionInitThenBuild: input.formatted(
                .filePath(name: .component().capitalization(.verbatim))
            )
        )
        XCTAssertTrue(Set([
            resultFrom.fileExtensionTwoInits,
            resultFrom.fileExtensionBuildThenInit,
            resultFrom.fileExtensionInitThenBuild
        ]).count == 1, "All format styles should return the same result")
        XCTAssertEqual(resultFrom.fileExtensionTwoInits, input)
        XCTAssertEqual(resultFrom.fileExtensionBuildThenInit, input)
        XCTAssertEqual(resultFrom.fileExtensionInitThenBuild, input)
    }
    
    func testFormatFilePath_withImplicitVerbatimStrategy() throws {
        let input: FileExtension = "FiLeNaMe.TxT"
        let resultFrom = (
            fileExtensionTwoInits: input.formatted(
                .filePath(name: .component())
            ),
            fileExtensionBuildThenInit: input.formatted(
                .filePath().name()
            ),
            fileExtensionInitThenBuild: input.formatted(
                .filePath()
            )
        )
        XCTAssertTrue(Set([
            resultFrom.fileExtensionTwoInits,
            resultFrom.fileExtensionBuildThenInit,
            resultFrom.fileExtensionInitThenBuild
        ]).count == 1, "All format styles should return the same result")
        XCTAssertEqual(resultFrom.fileExtensionTwoInits, input)
        XCTAssertEqual(resultFrom.fileExtensionBuildThenInit, input)
        XCTAssertEqual(resultFrom.fileExtensionInitThenBuild, input)
    }
    
    // MARK: File Name ONLY
    
    func testFormatFilePath_forOnlyNameComponent_withLowercaseStrategy() throws {
        let input: FileExtension = "FiLeNaMe.TxT"
        let resultFrom = (
            fileExtensionTwoInits: input.formatted(
                .filePath(name: .component(capitalization: .lowercased), extensionStyle: nil)
            ),
            fileExtensionBuildThenInit: input.formatted(
                .filePath(extensionStyle: nil).name(capitalization: .lowercased)
            ),
            fileExtensionInitThenBuild: input.formatted(
                .filePath(name: .component().capitalization(.lowercased), extensionStyle: nil)
            )
        )
        XCTAssertTrue(Set([
            resultFrom.fileExtensionTwoInits,
            resultFrom.fileExtensionBuildThenInit,
            resultFrom.fileExtensionInitThenBuild
        ]).count == 1, "All format styles should return the same result")
        XCTAssertEqual(resultFrom.fileExtensionTwoInits, "filename")
        XCTAssertEqual(resultFrom.fileExtensionBuildThenInit, "filename")
        XCTAssertEqual(resultFrom.fileExtensionInitThenBuild, "filename")
    }
    
    func testFormatFilePath_forOnlyNameComponent_withUppercaseStrategy() throws {
        let input: FileExtension = "FiLeNaMe.TxT"
        let resultFrom = (
            fileExtensionTwoInits: input.formatted(
                .filePath(name: .component(capitalization: .uppercase), extensionStyle: nil)
            ),
            fileExtensionBuildThenInit: input.formatted(
                .filePath(extensionStyle: nil).name(capitalization: .uppercase)
            ),
            fileExtensionInitThenBuild: input.formatted(
                .filePath(name: .component().capitalization(.uppercase), extensionStyle: nil)
            )
        )
        XCTAssertTrue(Set([
            resultFrom.fileExtensionTwoInits,
            resultFrom.fileExtensionBuildThenInit,
            resultFrom.fileExtensionInitThenBuild
        ]).count == 1, "All format styles should return the same result")
        XCTAssertEqual(resultFrom.fileExtensionTwoInits, "FILENAME")
        XCTAssertEqual(resultFrom.fileExtensionBuildThenInit, "FILENAME")
        XCTAssertEqual(resultFrom.fileExtensionInitThenBuild, "FILENAME")
    }
    
    func testFormatFilePath_forOnlyNameComponent_withCapitalizedStrategy() throws {
        let input: FileExtension = "FiLeNaMe.TxT"
        let resultFrom = (
            fileExtensionTwoInits: input.formatted(
                .filePath(name: .component(capitalization: .capitalized), extensionStyle: nil)
            ),
            fileExtensionBuildThenInit: input.formatted(
                .filePath(extensionStyle: nil).name(capitalization: .capitalized)
            ),
            fileExtensionInitThenBuild: input.formatted(
                .filePath(name: .component().capitalization(.capitalized), extensionStyle: nil)
            )
        )
        XCTAssertTrue(Set([
            resultFrom.fileExtensionTwoInits,
            resultFrom.fileExtensionBuildThenInit,
            resultFrom.fileExtensionInitThenBuild
        ]).count == 1, "All format styles should return the same result")
        XCTAssertEqual(resultFrom.fileExtensionTwoInits, "Filename")
        XCTAssertEqual(resultFrom.fileExtensionBuildThenInit, "Filename")
        XCTAssertEqual(resultFrom.fileExtensionInitThenBuild, "Filename")
    }
    
    func testFormatFilePath_forOnlyNameComponent_withCapitalizedStrategyAndSpace() throws {
        let input: FileExtension = "FiLe nAmE.TxT"
        let resultFrom = (
            fileExtensionTwoInits: input.formatted(
                .filePath(name: .component(capitalization: .capitalized), extensionStyle: nil)
            ),
            fileExtensionBuildThenInit: input.formatted(
                .filePath(extensionStyle: nil).name(capitalization: .capitalized)
            ),
            fileExtensionInitThenBuild: input.formatted(
                .filePath(name: .component().capitalization(.capitalized), extensionStyle: nil)
            )
        )
        XCTAssertTrue(Set([
            resultFrom.fileExtensionTwoInits,
            resultFrom.fileExtensionBuildThenInit,
            resultFrom.fileExtensionInitThenBuild
        ]).count == 1, "All format styles should return the same result")
        XCTAssertEqual(resultFrom.fileExtensionTwoInits, "File Name")
        XCTAssertEqual(resultFrom.fileExtensionBuildThenInit, "File Name")
        XCTAssertEqual(resultFrom.fileExtensionInitThenBuild, "File Name")
    }
    
    func testFormatFilePath_forOnlyNameComponent_withExplicitVerbatimStrategy() throws {
        let input: FileExtension = "FiLeNaMe.TxT"
        let resultFrom = (
            fileExtensionTwoInits: input.formatted(
                .filePath(name: .component(capitalization: .verbatim), extensionStyle: nil)
            ),
            fileExtensionBuildThenInit: input.formatted(
                .filePath(extensionStyle: nil).name(capitalization: .verbatim)
            ),
            fileExtensionInitThenBuild: input.formatted(
                .filePath(name: .component().capitalization(.verbatim), extensionStyle: nil)
            )
        )
        XCTAssertTrue(Set([
            resultFrom.fileExtensionTwoInits,
            resultFrom.fileExtensionBuildThenInit,
            resultFrom.fileExtensionInitThenBuild
        ]).count == 1, "All format styles should return the same result")
        XCTAssertEqual(resultFrom.fileExtensionTwoInits, "FiLeNaMe")
        XCTAssertEqual(resultFrom.fileExtensionBuildThenInit, "FiLeNaMe")
        XCTAssertEqual(resultFrom.fileExtensionInitThenBuild, "FiLeNaMe")
    }
    
    func testFormatFilePath_forOnlyNameComponent_withImplicitVerbatimStrategy() throws {
        let input: FileExtension = "FiLeNaMe.TxT"
        let resultFrom = (
            fileExtensionTwoInits: input.formatted(
                .filePath(name: .component(), extensionStyle: nil)
            ),
            fileExtensionBuildThenInit: input.formatted(
                .filePath(extensionStyle: nil).name()
            ),
            fileExtensionInitThenBuild: input.formatted(
                .filePath(extensionStyle: nil)
            )
        )
        XCTAssertTrue(Set([
            resultFrom.fileExtensionTwoInits,
            resultFrom.fileExtensionBuildThenInit,
            resultFrom.fileExtensionInitThenBuild
        ]).count == 1, "All format styles should return the same result")
        XCTAssertEqual(resultFrom.fileExtensionTwoInits, "FiLeNaMe")
        XCTAssertEqual(resultFrom.fileExtensionBuildThenInit, "FiLeNaMe")
        XCTAssertEqual(resultFrom.fileExtensionInitThenBuild, "FiLeNaMe")
    }
    
    // MARK: Path Extension Only
    func testFormatFilePath_forOnlyPathExtensionComponent_withLowercaseStrategy() throws {
        let input: FileExtension = "FiLeNaMe.TxT"
        let resultFrom = (
            fileExtensionTwoInits: input.formatted(
                .filePath(name: nil, extensionStyle: .component(capitalization: .lowercased))
            ),
            fileExtensionBuildThenInit: input.formatted(
                .filePath(name: nil).pathExtension(capitalization: .lowercased)
            ),
            fileExtensionInitThenBuild: input.formatted(
                .filePath(name: nil, extensionStyle: .component().capitalization(.lowercased))
            )
        )
        XCTAssertTrue(Set([
            resultFrom.fileExtensionTwoInits,
            resultFrom.fileExtensionBuildThenInit,
            resultFrom.fileExtensionInitThenBuild
        ]).count == 1, "All format styles should return the same result")
        XCTAssertEqual(resultFrom.fileExtensionTwoInits, "txt")
        XCTAssertEqual(resultFrom.fileExtensionBuildThenInit, "txt")
        XCTAssertEqual(resultFrom.fileExtensionInitThenBuild, "txt")
    }
    
    func testFormatFilePath_forOnlyPathExtensionComponent_withUppercaseStrategy() throws {
        let input: FileExtension = "FiLeNaMe.TxT"
        let resultFrom = (
            fileExtensionTwoInits: input.formatted(
                .filePath(name: nil, extensionStyle: .component(capitalization: .uppercase))
            ),
            fileExtensionBuildThenInit: input.formatted(
                .filePath(name: nil).pathExtension(capitalization: .uppercase)
            ),
            fileExtensionInitThenBuild: input.formatted(
                .filePath(name: nil, extensionStyle: .component().capitalization(.uppercase))
            )
        )
        XCTAssertTrue(Set([
            resultFrom.fileExtensionTwoInits,
            resultFrom.fileExtensionBuildThenInit,
            resultFrom.fileExtensionInitThenBuild
        ]).count == 1, "All format styles should return the same result")
        XCTAssertEqual(resultFrom.fileExtensionTwoInits, "TXT")
        XCTAssertEqual(resultFrom.fileExtensionBuildThenInit, "TXT")
        XCTAssertEqual(resultFrom.fileExtensionInitThenBuild, "TXT")
    }
    
    func testFormatFilePath_forOnlyPathExtensionComponent_withCapitalizedStrategy() throws {
        let input: FileExtension = "FiLeNaMe.TxT"
        let resultFrom = (
            fileExtensionTwoInits: input.formatted(
                .filePath(name: nil, extensionStyle: .component(capitalization: .capitalized))
            ),
            fileExtensionBuildThenInit: input.formatted(
                .filePath(name: nil).pathExtension(capitalization: .capitalized)
            ),
            fileExtensionInitThenBuild: input.formatted(
                .filePath(name: nil, extensionStyle: .component().capitalization(.capitalized))
            )
        )
        XCTAssertTrue(Set([
            resultFrom.fileExtensionTwoInits,
            resultFrom.fileExtensionBuildThenInit,
            resultFrom.fileExtensionInitThenBuild
        ]).count == 1, "All format styles should return the same result")
        XCTAssertEqual(resultFrom.fileExtensionTwoInits, "Txt")
        XCTAssertEqual(resultFrom.fileExtensionBuildThenInit, "Txt")
        XCTAssertEqual(resultFrom.fileExtensionInitThenBuild, "Txt")
    }
    
    func testFormatFilePath_forOnlyPathExtensionComponent_withCapitalizedStrategyAndSpace() throws {
        let input: FileExtension = "FiLe nAmE.T xT"
        let resultFrom = (
            fileExtensionTwoInits: input.formatted(
                .filePath(name: nil, extensionStyle: .component(capitalization: .capitalized))
            ),
            fileExtensionBuildThenInit: input.formatted(
                .filePath(name: nil).pathExtension(capitalization: .capitalized)
            ),
            fileExtensionInitThenBuild: input.formatted(
                .filePath(name: nil, extensionStyle: .component().capitalization(.capitalized))
            )
        )
        XCTAssertTrue(Set([
            resultFrom.fileExtensionTwoInits,
            resultFrom.fileExtensionBuildThenInit,
            resultFrom.fileExtensionInitThenBuild
        ]).count == 1, "All format styles should return the same result")
        XCTAssertEqual(resultFrom.fileExtensionTwoInits, "T Xt")
        XCTAssertEqual(resultFrom.fileExtensionBuildThenInit, "T Xt")
        XCTAssertEqual(resultFrom.fileExtensionInitThenBuild, "T Xt")
    }
    
    func testFormatFilePath_forOnlyPathExtensionComponent_withExplicitVerbatimStrategy() throws {
        let input: FileExtension = "FiLeNaMe.TxT"
        let resultFrom = (
            fileExtensionTwoInits: input.formatted(
                .filePath(name: nil, extensionStyle: .component(capitalization: .verbatim))
            ),
            fileExtensionBuildThenInit: input.formatted(
                .filePath(name: nil).pathExtension(capitalization: .verbatim)
            ),
            fileExtensionInitThenBuild: input.formatted(
                .filePath(name: nil, extensionStyle: .component().capitalization(.verbatim))
            )
        )
        XCTAssertTrue(Set([
            resultFrom.fileExtensionTwoInits,
            resultFrom.fileExtensionBuildThenInit,
            resultFrom.fileExtensionInitThenBuild
        ]).count == 1, "All format styles should return the same result")
        XCTAssertEqual(resultFrom.fileExtensionTwoInits, "TxT")
        XCTAssertEqual(resultFrom.fileExtensionBuildThenInit, "TxT")
        XCTAssertEqual(resultFrom.fileExtensionInitThenBuild, "TxT")
    }
    
    func testFormatFilePath_forOnlyPathExtensionComponent_withImplicitVerbatimStrategy() throws {
        let input: FileExtension = "FiLeNaMe.TxT"
        let resultFrom = (
            fileExtensionTwoInits: input.formatted(
                .filePath(name: nil, extensionStyle: .component())
            ),
            fileExtensionBuildThenInit: input.formatted(
                .filePath(name: nil).pathExtension()
            ),
            fileExtensionInitThenBuild: input.formatted(
                .filePath(name: nil)
            )
        )
        XCTAssertTrue(Set([
            resultFrom.fileExtensionTwoInits,
            resultFrom.fileExtensionBuildThenInit,
            resultFrom.fileExtensionInitThenBuild
        ]).count == 1, "All format styles should return the same result")
        XCTAssertEqual(resultFrom.fileExtensionTwoInits, "TxT")
        XCTAssertEqual(resultFrom.fileExtensionBuildThenInit, "TxT")
        XCTAssertEqual(resultFrom.fileExtensionInitThenBuild, "TxT")
    }
    
    // MARK: - Provide Character Sets -
    func testFormatFilePath_removeWhiteSpace_withCapitalizedStrategyAndSpace() throws {
        let input: FileExtension = "FiLe nAmE.TxT"
        let resultFrom = (
            fileExtensionTwoInits: input.formatted(
                .filePath(name: .component(capitalization: .capitalized, removingCharactersIn: .whitespaces), extensionStyle: .component(capitalization: .lowercased))
            ),
            fileExtensionBuildThenInit: input.formatted(
                .filePath().name(capitalization: .capitalized, removingCharactersIn: .whitespaces).pathExtension(capitalization: .lowercased)
            ),
            fileExtensionInitThenBuild: input.formatted(
                .filePath(name: .component().capitalization(.capitalized).remove(charactersIn: .whitespaces), extensionStyle: .component(capitalization: .lowercased))
            )
        )
        let results = [
            resultFrom.fileExtensionTwoInits,
            resultFrom.fileExtensionBuildThenInit,
            resultFrom.fileExtensionInitThenBuild
        ]
        XCTAssertTrue(Set(results).count == 1, "All format styles should return the same result: \(results.joined(separator: ", "))")
        XCTAssertEqual(resultFrom.fileExtensionTwoInits, "FileName.txt")
        XCTAssertEqual(resultFrom.fileExtensionBuildThenInit, "FileName.txt")
        XCTAssertEqual(resultFrom.fileExtensionInitThenBuild, "FileName.txt")
    }
}
