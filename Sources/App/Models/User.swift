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
    var balance: Int 


    @Field(key: "hasFullVersion")
    var hasFullVersion: Bool

    @Field(key: "lastPlayTime")
    var lastPlayTime: Date?


    @Field(key: "unlimitedUnits")
    var unlimitedUnits: Bool

    @Field(key: "usedSoldiers")
    var usedSoldiers: Int

    @Field(key: "usedTanks")
    var usedTanks: Int

    @Field(key: "usedPlanes")
    var usedPlanes: Int


    @Children(for: \.$user)
    var transactions: [Transaction]

    init() { 
        self.hasFullVersion = false
        self.lastPlayTime = nil
    }

    init(id: UUID? = nil, username: String, email: String, balance: Int = 0, hasFullVersion: Bool = false, lastPlayTime: Date? = nil) {
        self.id = id
        self.username = username
        self.email = email
        self.balance = balance
        self.hasFullVersion = hasFullVersion
        self.lastPlayTime = lastPlayTime
        self.unlimitedUnits = false
        self.usedSoldiers = 0
        self.usedTanks = 0
        self.usedPlanes = 0
    }
}