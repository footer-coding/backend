
import Vapor
import Fluent
import FluentMongoDriver

struct TransactionHistoryResponse: Content {
    let date: String
    let amount: Int
    let status: String

    init(date: Date, amount: Int, status: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        self.date = dateFormatter.string(from: date)
        self.amount = amount
        self.status = status
    }
}