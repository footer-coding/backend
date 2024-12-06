
import Fluent
import Vapor
import StripeKit
import FluentMongoDriver

final class Transaction: Model, Content {
    
    static let schema = "transactions"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "userId")
    var userId: String

    @Field(key: "amount")
    var amount: Int

    @Field(key: "paymentIntentId")
    var paymentIntentId: String

    init() { }

    init(id: UUID? = nil, userId: String, amount: Int, paymentIntentId: String) {
        self.id = id
        self.userId = userId
        self.amount = amount
        self.paymentIntentId = paymentIntentId
    }
}