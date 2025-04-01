import UIKit

/**
Defines actions to be dispatched from `ViewType`  to `ViewModelType`.

 - Attention:
   - `ActionType` works as the input boundary for `ViewModelType`
   - `ActionType` should only be dispatched from UI Layer by `ViewType`
   - `ViewType` should only interact with `ViewModelType` through `ActionType`
   - The flow is: `ViewType`  ➡️ `ActionType` ➡️ `ViewModelType`
 
 You dispatch action from a `ViewType`:
 
     // dispatchs an action from a view controller
     viewModel.dispatch(action)
 
You usually define actions with `Enum` type.
*/
@MainActor
public protocol ActionType { }

/**
Defines commands to be invoked by a `ViewModelType` and executed by a `ViewType`.

 - Attention:
   - `CommandType` works as the output boundary for `ViewModelType`
   - `CommandType` should only be invoked by `ViewModelType`
   - `ViewModelType` should only interact with `ViewType` through `CommandType`
   - the flow is: `ViewModelType` ➡️ `CommandType` ➡️ `ViewType`
 
 You invoke a command from a `ViewModelType`:
 
     // A command gets invoked from a view model
     invokeCommand?(command)

You usually define commands with `Enum` type.
*/
@MainActor
public protocol CommandType { }

/**
Defines a view model to manage the inputs and outputs through `ActionType` and `CommandType`.
By using the actions and commands, we make the a unidirectional flow between `ViewType` and `ViewModelType`.

 - Attention:
   - Unidirectional flow: `ViewType` ➡️ `ActionType` ➡️ `ViewModelType` ➡️ `CommandType` ➡️ `ViewType`
   - `ViewModelType` should not dispatch `ActionType`, which breaks the unidirectional flow
 
 A `ViewModelType` receives actions and invokes commands for a command subscriber:
 
     func dispatch(_ action: Action) {
        // Handle actions and invoke commands
        invokeCommand?(command)
     }
*/
@MainActor
public protocol ViewModelType {
    associatedtype Action: ActionType
    associatedtype Command: CommandType
    
    var invokeCommand: ((Command) -> Void)? { get set }
    
    func dispatch(_ action: Action)
}

/**
Defines a view which subscribes `CommandType` and executes `CommandType` when it gets invoked from `ViewModelType`.

 - Attention:
   - Unidirectional flow: `ViewType` ➡️ `ActionType` ➡️ `ViewModelType` ➡️ `CommandType` ➡️ `ViewType`
   - `ViewType` should not invoke a `CommandType`, which breaks the unidirectional flow
 
 For example:
 
     // Subscribes command
     viewModel.invokeCommand = { [weak self] command in
         DispatchQueue.main.async { self?.executeCommand(command) }
     }
    
     func executeCommand(_ command: Command) {
         // Executes command
     }

You usually define `UIViewController` as a `ViewType`
*/
@MainActor
public protocol ViewType {
    associatedtype Command: CommandType
    
    func executeCommand(_ command: Command)
}

/**
 Defines a router with the ability to build a view controller and start a navigation flow
 
 - Attention:
    - Router needs to be protocol oriented, and owned by a `ViewModelType`
    - Router calls back to `ViewModelType` through closures
    - Router holds weak references to it's base view controller if needed
    - Router holds weak references to it's containing `UINavigationController`
 */
@preconcurrency @MainActor
public protocol Routing {
    func build() -> UIViewController
    func start()
}
