@testable import MEGA
import MEGAPresentation
import XCTest

extension XCTestCase {
    
    func test<T: ViewModelType>(viewModel: T, action: T.Action, expectedCommands: [T.Command], timeout: TimeInterval = 3.0, file: StaticString = #filePath, line: UInt = #line) where T.Command: Equatable {
        test(
            viewModel: viewModel,
            actions: [action],
            expectedCommands: expectedCommands, 
            timeout: timeout,
            expectationValidation: ==,
            file: file,
            line: line
        )
    }
    
    func test<T: ViewModelType>(viewModel: T, actions: [T.Action], expectedCommands: [T.Command], timeout: TimeInterval = 3.0, file: StaticString = #filePath, line: UInt = #line) where T.Command: Equatable {
        test(
            viewModel: viewModel,
            actions: actions,
            expectedCommands: expectedCommands,
            timeout: timeout,
            expectationValidation: ==,
            file: file,
            line: line
        )
    }
    
    func test<T: ViewModelType>(viewModel: T, action: T.Action, expectedCommands: [T.Command], timeout: TimeInterval = 3.0, expectationValidation: @escaping (T.Command, T.Command) -> Bool, file: StaticString = #filePath, line: UInt = #line) {
        test(
            viewModel: viewModel,
            actions: [action],
            expectedCommands: expectedCommands,
            timeout: timeout,
            expectationValidation: expectationValidation,
            file: file,
            line: line
        )
    }
    
    func test<T: ViewModelType>(viewModel: T, actions: [T.Action], expectedCommands: [T.Command], timeout: TimeInterval = 3.0, expectationValidation: @escaping (T.Command, T.Command) -> Bool, file: StaticString = #filePath, line: UInt = #line) {
        var expectedCommands = expectedCommands
        var viewModel = viewModel
        
        let commandExpectation = expectation(description: "all commands are executed")
        
        // Fulfill the expectation if we don't expect any commands invoked from the view model
        if expectedCommands.isEmpty {
            commandExpectation.fulfill()
        }
        
        // Subscribe the invoke command event
        viewModel.invokeCommand = { command in
            let expect = expectedCommands.removeFirstWithAssertion()
            guard expectationValidation(expect, command) else {
                XCTFail("received command \(command) is not \(expect)", file: file, line: line)
                return
            }
            
            if expectedCommands.isEmpty {
                commandExpectation.fulfill()
            }
        }
        
        // Dispatch actions
        for action in actions {
            viewModel.dispatch(action)
        }
        
        wait(for: [commandExpectation], timeout: timeout)
    }
    
    @MainActor
    func test<T: ViewModelType>(viewModel: T, action: T.Action, expectedCommands: [T.Command], timeout: TimeInterval = 3.0, file: StaticString = #filePath, line: UInt = #line) async where T.Command: Equatable {
        await test(
            viewModel: viewModel,
            actions: [action],
            expectedCommands: expectedCommands,
            timeout: timeout,
            expectationValidation: ==,
            file: file,
            line: line
        )
    }
    
    @MainActor
    func test<T: ViewModelType>(viewModel: T, actions: [T.Action], expectedCommands: [T.Command], timeout: TimeInterval = 3.0, expectationValidation: @escaping (T.Command, T.Command) -> Bool, file: StaticString = #filePath, line: UInt = #line) async {
        var expectedCommands = expectedCommands
        var viewModel = viewModel
        
        let commandExpectation = expectation(description: "all commands are executed")
        
        // Fulfil the expectation if we don't expect any commands invoked from the view model
        if expectedCommands.isEmpty {
            commandExpectation.fulfill()
        }
        
        // Subscribe the invoke command event
        viewModel.invokeCommand = { command in
            let expect = expectedCommands.removeFirstWithAssertion()
            guard expectationValidation(expect, command) else {
                XCTFail("received command \(command) is not \(expect)", file: file, line: line)
                return
            }
            
            if expectedCommands.isEmpty {
                commandExpectation.fulfill()
            }
        }
        
        // Dispatch actions
        for action in actions {
            viewModel.dispatch(action)
        }
        
        await fulfillment(of: [commandExpectation], timeout: timeout)
    }
    
    @MainActor
    func test<T: ViewModelType>(viewModel: T, trigger: () -> Void, expectedCommands: [T.Command], timeout: TimeInterval = 3.0, file: StaticString = #filePath, line: UInt = #line) async where T.Command: Equatable {
        await test(viewModel: viewModel, trigger: trigger, expectedCommands: expectedCommands, expectationValidation: ==, file: file, line: line)
    }
    
    @MainActor
    func test<T: ViewModelType>(viewModel: T, trigger: () -> Void, expectedCommands: [T.Command], timeout: TimeInterval = 3.0, expectationValidation: @escaping (T.Command, T.Command) -> Bool, file: StaticString = #filePath, line: UInt = #line) async {
        var expectedCommands = expectedCommands
        var viewModel = viewModel
        
        let commandExpectation = expectation(description: "all commands are executed")
        
        // Fulfil the expectation if we don't expect any commands invoked from the view model
        if expectedCommands.isEmpty {
            commandExpectation.fulfill()
        }
        
        // Subscribe the invoke command event
        viewModel.invokeCommand = { command in
            let expect = expectedCommands.removeFirstWithAssertion()
            guard expectationValidation(expect, command) else {
                XCTFail("received command \(command) is not \(expect)", file: file, line: line)
                return
            }
            
            if expectedCommands.isEmpty {
                commandExpectation.fulfill()
            }
        }
        
        // Dispatch actions
        trigger()
        
        await fulfillment(of: [commandExpectation], timeout: timeout)
    }
    
    func test<T: ViewModelType>(viewModel: T, trigger: () -> Void, expectedCommands: [T.Command], timeout: TimeInterval = 3.0, expectationValidation: @escaping (T.Command, T.Command) -> Bool, file: StaticString = #filePath, line: UInt = #line) {
        var expectedCommands = expectedCommands
        var viewModel = viewModel
        
        let commandExpectation = expectation(description: "all commands are executed")
        
        // Fulfil the expectation if we don't expect any commands invoked from the view model
        if expectedCommands.isEmpty {
            commandExpectation.fulfill()
        }
        
        // Subscribe the invoke command event
        viewModel.invokeCommand = { command in
            let expect = expectedCommands.removeFirstWithAssertion()
            guard expectationValidation(expect, command) else {
                XCTFail("received command \(command) is not \(expect)", file: file, line: line)
                return
            }
            
            if expectedCommands.isEmpty {
                commandExpectation.fulfill()
            }
        }
        
        // Dispatch actions
        trigger()
        
        wait(for: [commandExpectation], timeout: timeout)
    }
    
    func test<T: ViewModelType>(viewModel: T, actions: [T.Action], relaysCommand: T.Command, timeout: TimeInterval = 3.0) where T.Command: Equatable {
        var viewModel = viewModel
        let commandExpectation = expectation(description: "relays command")
        viewModel.invokeCommand = { command in
            if command == relaysCommand {
                commandExpectation.fulfill()
            }
        }
        
        for action in actions {
            viewModel.dispatch(action)
        }
        
        wait(for: [commandExpectation], timeout: timeout)
    }
}
