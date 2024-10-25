@testable import MEGA

public final class MockMOUser {
    var firstname: String?
    var lastname: String?
    var nickname: String?
    var email: String?
    
    public init(firstname: String? = nil, lastname: String? = nil, nickname: String? = nil, email: String? = nil) {
        self.firstname = firstname
        self.lastname = lastname
        self.nickname = nickname
        self.email = email
    }
    
    public func toMOUser(context: NSManagedObjectContext) -> MOUser {
        let moUser = NSEntityDescription.insertNewObject(forEntityName: "User", into: context) as! MOUser
                
        moUser.firstname = self.firstname
        moUser.lastname = self.lastname
        moUser.nickname = self.nickname
        moUser.email = self.email
        
        return moUser
    }
}
