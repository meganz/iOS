import XCTest
@testable import MEGA

extension XCTestCase {
    func test<T: ViewModelType>(viewModel: T, action: T.Action, expectedCommands: [T.Command], timeout: TimeInterval = 0.5) where T.Command: Equatable {
        var expectedCommands = expectedCommands
        var viewModel = viewModel
        
        let commandExpectation = expectation(description: "all commands are executed")
        
        // Fulfill the expectaion if we don't expect any commands invoked from the view model
        if expectedCommands.isEmpty {
            commandExpectation.fulfill()
        }
        
        // Subscribe the invoke command event
        viewModel.invokeCommand = { command in
            let expect = expectedCommands.removeFirstWithAssertion()
            guard expect == command else {
                XCTFail("received command \(command) is not \(expect)")
                return
            }
            
            if expectedCommands.isEmpty {
                commandExpectation.fulfill()
            }
        }
        
        // Dispatch action
        viewModel.dispatch(action)
        
        wait(for: [commandExpectation], timeout: timeout)
    }
}
