import Fluent
import Vapor

final class Transaction: Model, Content {
    static let schema = "transactions"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "date")
    var date: Date

    @Field(key: "isConfirmed")
    var isConfirmed: Bool

    @Field(key: "paymentLink")
    var paymentLink: String

    @Field(key: "amount")
    var amount: Int

    @Parent(key: "user_id")
    var user: User

    init() { }

    init(id: UUID? = nil, date: Date, isConfirmed: Bool, userId: UUID, paymentLink: String, amount: Int) {
        self.id = id
        self.date = date
        self.isConfirmed = isConfirmed
        self.$user.id = userId
        self.paymentLink = paymentLink
        self.amount = amount
    }
}