/// Convenient class to simulate a function call for mocking purpose
/// Usage: Assuming we have a protocol
///
///     protocol MyProtocol {
///     func foo(_ x: Int, y: Float) -> Bool
///     }
///
/// We can mock it like this:
///
///     final class MockMyProto: MyProtocol {
///         let fooMock = FuncCallRecorder<(Int, Int), Int>()
///         func foo(_ x: Int, y: Float) -> Bool {
///             generateRecorder.call((x, y))
///         }
///     }
/// Then in our test code, we can convenience use it for assertion:
///
///     func testCase() {
///         let mock = MockMyProto()
///         mock.foo(1, 2.0)
///         XCTAssertTrue(mock.fooMock.called)
///         XCTAssertEqual(mock.fooMock.callCount)
///         XCTAssertEqual(mock.fooMock.arguments, [(1, 2.0)])
///     }
/// }
///
final class FuncCallRecorder<Argument, Return> {
    var arguments = [Argument]()
    var stubbedReturns: Return?
    
    func call(_ args: Argument) -> Return {
        arguments.append(args)
        guard let nonNilReturn = call(args) else {
            fatalError("stubbedReturns must be set")
        }
        return nonNilReturn
    }
    
    func call(_ args: Argument) -> Return? {
        arguments.append(args)
        return stubbedReturns
    }
}

extension FuncCallRecorder {
    var callCount: Int { arguments.count }
    var called: Bool { !arguments.isEmpty }
}

extension FuncCallRecorder where Argument == Void {
    func call() -> Return { call(()) }
    func call() -> Return? { call(()) }
}

extension FuncCallRecorder where Return == Void {
    func call(_ args: Argument) {
        arguments.append(args)
    }
}

extension FuncCallRecorder where Argument == Void, Return == Void {
    func call() {
        arguments.append(())
    }
}
