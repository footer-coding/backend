import Fluent
import Vapor

final class BitcoinTransaction: Model, Content {
    static let schema = "bitcoin_transactions"
    
    @ID(custom: "_id")
    var id: String?
    
    @Field(key: "username")
    var username: String
    
    @Field(key: "amount")
    var amount: Int
    
    @Field(key: "isConfirmed")
    var isConfirmed: Bool
    
    @Field(key: "date")
    var date: Date
    
    init() { }
    
    init(id: String? = nil, username: String, amount: Int, isConfirmed: Bool, date: Date) {
        self.id = id
        self.username = username
        self.amount = amount
        self.isConfirmed = isConfirmed
        self.date = date
    }
    
    // Dodaj wymagany typ IDValue
    typealias IDValue = String
}