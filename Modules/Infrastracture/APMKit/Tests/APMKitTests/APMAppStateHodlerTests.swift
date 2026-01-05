@testable import APMKit
@testable import APMKitMocks
import Foundation
import Testing
import UIKit

@Suite("APMAppStateHolder Tests")
struct APMAppStateHolderTests {
    @Test("isInForeground becomes false when willResignActive notification is received")
    func test_resignActiveNotification() async {
        let mockNC = MockNotificationCenter()
        let sut = APMAppStateHolder(notificationCenter: mockNC)
        try? await Task.sleep(for: .milliseconds(100))
        
        mockNC.post(name: UIApplication.willResignActiveNotification, object: nil)
        
        #expect(sut.isInForeground == false)
    }
    
    @Test("isInForeground becomes true when didBecomeActive notification is received")
    func test_becomeActiveNotification() async {
        let mockNC = MockNotificationCenter()
        let sut = APMAppStateHolder(notificationCenter: mockNC)
        try? await Task.sleep(for: .milliseconds(100))
        
        mockNC.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        
        #expect(sut.isInForeground == true)
    }
    
    @Test("State transitions correctly through multiple foreground/background cycles")
    func test_multipleStateTransitions() async {
        let mockNC = MockNotificationCenter()
        let sut = APMAppStateHolder(notificationCenter: mockNC)
        let appState = await UIApplication.shared.applicationState
        try? await Task.sleep(for: .milliseconds(100))
        
        #expect(sut.isInForeground == (appState == .active))
        
        mockNC.post(name: UIApplication.willResignActiveNotification, object: nil)
        #expect(sut.isInForeground == false)
        
        mockNC.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        #expect(sut.isInForeground == true)
        
        mockNC.post(name: UIApplication.willResignActiveNotification, object: nil)
        #expect(sut.isInForeground == false)
        
        mockNC.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        #expect(sut.isInForeground == true)
    }
    
    @Test("Duplicate resignActive notifications keep state as false")
    func test_duplicateResignActive() async {
        let mockNC = MockNotificationCenter()
        let sut = APMAppStateHolder(notificationCenter: mockNC)
        try? await Task.sleep(for: .milliseconds(100))
        
        mockNC.post(name: UIApplication.willResignActiveNotification, object: nil)
        mockNC.post(name: UIApplication.willResignActiveNotification, object: nil)
        
        #expect(sut.isInForeground == false)
    }
    
    @Test("Duplicate becomeActive notifications keep state as true")
    func test_duplicateBecomeActive() async {
        let mockNC = MockNotificationCenter()
        let sut = APMAppStateHolder(notificationCenter: mockNC)
        try? await Task.sleep(for: .milliseconds(100))
        
        mockNC.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        mockNC.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        
        #expect(sut.isInForeground == true)
    }
}
