import Fluent
import Vapor

final class User: Model, Content {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "username")
    var username: String
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "balance")
<<<<<<< HEAD
    var balance: Int 

    @Field(key: "hasFullVersion")
    var hasFullVersion: Bool

    @Field(key: "lastPlayTime")
    var lastPlayTime: Date?

    @Children(for: \.$user)
    var transactions: [Transaction]

    init() { 
        self.hasFullVersion = false
        self.lastPlayTime = nil
    }

    init(id: UUID? = nil, username: String, email: String, balance: Int = 0, hasFullVersion: Bool = false, lastPlayTime: Date? = nil) {
=======
    var balance: Int
    
    @Children(for: \.$user)
    var transactions: [Transaction]
    
    init() { }
    
    init(id: UUID? = nil, username: String, email: String, balance: Int = 0) {
>>>>>>> b4ef51d7855b44b9d4d8271c606e471348875202
        self.id = id
        self.username = username
        self.email = email
        self.balance = balance
        self.hasFullVersion = hasFullVersion
        self.lastPlayTime = lastPlayTime
    }
}