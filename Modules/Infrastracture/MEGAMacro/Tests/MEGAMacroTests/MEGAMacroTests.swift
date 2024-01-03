import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(MEGAMacroMacros)
import MEGAMacroMacros

let testMacros: [String: Macro.Type] = [
    "newRepo": NewRepoMacro.self,
]
#endif

final class MEGAMacroTests: XCTestCase {
    func testExpansion_addNewRepo_noError() throws {
#if canImport(MEGAMacroMacros)
        assertMacroExpansion(
        """
        @newRepo(MEGASDK.shared)
        struct TestRepo {}
        """,
        expandedSource:
        """
        struct TestRepo {

          public static var newRepo: TestRepo {
              TestRepo(sdk: MEGASDK.shared)
          }

          private let sdk: MEGASDK

          public init(sdk:MEGASDK) { self.sdk = sdk }}

        extension TestRepo: RepositoryProtocol {
        }
        """,
        macros: testMacros,
        indentationWidth: .spaces(2))
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }
    
    func testExpansion_addNewRepoToEnum_typeError() throws {
#if canImport(MEGAMacroMacros)
        assertMacroExpansion(
        """
        @newRepo(MEGASDK.shared)
        enum TestEnum {}
        """,
        expandedSource:
        """
        enum TestEnum {}
        """,
        diagnostics: [
            DiagnosticSpec(message: "@newRepo requires a class or struct declaration", line: 1, column: 1, severity: .error)
        ],
        macros: testMacros,
        indentationWidth: .spaces(2))
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }
    
    func testExpansion_addNewRepoWithoutArgument_argumentError() throws {
#if canImport(MEGAMacroMacros)
        assertMacroExpansion(
        """
        @newRepo
        struct TestRepo {}
        """,
        expandedSource:
        """
        struct TestRepo {}
        """,
        diagnostics: [
            DiagnosticSpec(message: #"@newRepo requires SDK instance as an argument, in the form "MEGASDK.shared"."#, line: 1, column: 1, severity: .error)
        ],
        macros: testMacros,
        indentationWidth: .spaces(2))
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }
}
