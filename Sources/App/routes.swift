import Vapor
import DotEnv
import StripeKit
import Fluent 
import FluentMongoDriver

let fullVersionPrice = 8000

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }            

    app.get("test") { req -> Response in
        let filePath = app.directory.publicDirectory + "Client/index.html"
        return req.fileio.streamFile(at: filePath)
    }

    app.get("stronka") { req -> Response in 
        let filePath = app.directory.publicDirectory + "Redirect.html"
        return req.fileio.streamFile(at: filePath)
    }

    app.get("register") { req async throws -> Response in
        let payload = try await req.jwt.verify(as: JWTModel.self)
        let user = User(username: payload.user, email: payload.email)
        try await user.save(on: req.db)
        return Response(status: .ok, body: .init(string: "User registered successfully"))
    }

    app.post("create-payment-intent") { req async throws -> Response in
        do {
            let items = try req.content.decode([String: [Item]].self)["items"] ?? []
            let payload = try await req.jwt.verify(as: JWTModel.self)
            let username = payload.user

            print("Items: \(items)")
            
            let amount = calculateOrderAmount(items: items)
            
            guard amount > 0 else {
                throw Abort(.badRequest, reason: "Invalid amount")
            }

            guard let user = try await User.query(on: req.db)
                .filter(\.$username == username)
                .first() else {
                throw Abort(.notFound, reason: "User not found")
            }

            if amount == fullVersionPrice {
                if user.balance < fullVersionPrice {
                    return Response(status: .badRequest, body: .init(string: "Insufficient funds in balance"))
                }
                user.balance -= fullVersionPrice
                user.hasFullVersion = true
                try await user.save(on: req.db)
                return Response(status: .ok, body: .init(string: "Full version activated"))
            }

            let paymentIntent = try await req.application.stripe.paymentIntents.create(
                amount: amount,
                currency: .pln,
                automaticPaymentMethods: nil,
                confirm: false,
                customer: nil,
                description: nil,
                metadata: nil,
                offSession: nil,
                paymentMethod: nil,
                receiptEmail: nil,
                setupFutureUsage: nil,
                shipping: nil,
                statementDescriptor: nil,
                statementDescriptorSuffix: nil,
                applicationFeeAmount: nil,
                captureMethod: nil,
                confirmationMethod: nil,
                errorOnRequiresAction: nil,
                mandate: nil,
                mandateData: nil,
                onBehalfOf: nil,
                paymentMethodData: nil,
                paymentMethodOptions: nil,
                paymentMethodTypes: ["card"],
                radarOptions: nil,
                returnUrl: nil,
                transferData: nil,
                transferGroup: nil,
                useStripeSDK: nil,
                expand: nil
            )
            
            print("PaymentIntent created: \(paymentIntent)")

            // Update user balance
            try await updateUserBalance(username: user.username, amount: amount, on: req.db)
            
            // Save transaction to database
            let transactionLink = "https://dashboard.stripe.com/payments/\(paymentIntent.id)"
            let transaction = Transaction(date: Date(), isConfirmed: false, userId: user.id!, paymentLink: transactionLink, amount: amount)
            try await transaction.save(on: req.db)

            // Check if the amount is fullVersionPrice
            if amount == fullVersionPrice {
                user.hasFullVersion = true
                try await user.save(on: req.db)
                return Response(status: .ok, body: .init(string: "Full version activated"))
            }
            
            var response: [String: String] = [
                "clientSecret": paymentIntent.clientSecret ?? "",
                "paymentIntent": paymentIntent.clientSecret ?? "",
                "dpmCheckerLink": "https://dashboard.stripe.com/settings/payment_methods/review?transaction_id=\(paymentIntent.id)"
            ]
            
            print("Response: \(response)")

            return Response(status: .ok, body: .init(data: try JSONEncoder().encode(response)))
        } catch {
            print("Error creating payment intent: \(error)")
            throw Abort(.internalServerError, reason: "Failed to create payment intent: \(error.localizedDescription)")
        }
    }

    app.post("create-payment-sheet") { req async throws -> Response in
        do {
            let items = try req.content.decode([String: [Item]].self)["items"] ?? []
            let payload = try await req.jwt.verify(as: JWTModel.self)
            let username = payload.user
            
            let amount = calculateOrderAmount(items: items)
            
            guard amount > 0 else {
                throw Abort(.badRequest, reason: "Invalid amount")
            }

            guard let user = try await User.query(on: req.db)
                .filter(\.$username == username)
                .first() else {
                throw Abort(.notFound, reason: "User not found")
            }

            if amount == fullVersionPrice {
                if user.balance < fullVersionPrice {
                    return Response(status: .badRequest, body: .init(string: "Insufficient funds in balance"))
                }
                user.balance -= fullVersionPrice
                user.hasFullVersion = true
                try await user.save(on: req.db)
                return Response(status: .ok, body: .init(string: "Full version activated"))
            }

            let paymentIntent = try await req.application.stripe.paymentIntents.create(
                amount: amount,
                currency: .pln,
                automaticPaymentMethods: ["enabled": true],
                confirm: false,
                customer: nil,
                description: nil,
                metadata: nil,
                offSession: nil,
                paymentMethod: nil,
                receiptEmail: nil,
                setupFutureUsage: nil,
                shipping: nil,
                statementDescriptor: nil,
                statementDescriptorSuffix: nil,
                applicationFeeAmount: nil,
                captureMethod: nil,
                confirmationMethod: nil,
                errorOnRequiresAction: nil,
                mandate: nil,
                mandateData: nil,
                onBehalfOf: nil,
                paymentMethodData: nil,
                paymentMethodOptions: nil,
                paymentMethodTypes: ["card"],
                radarOptions: nil,
                returnUrl: nil,
                transferData: nil,
                transferGroup: nil,
                useStripeSDK: nil,
                expand: nil
            )
            
            print("PaymentIntent created: \(paymentIntent)")

            // Update user balance
            try await updateUserBalance(username: user.username, amount: amount, on: req.db)
            
            // Save transaction to database
            let transactionLink = "https://dashboard.stripe.com/payments/\(paymentIntent.id)"
            let transaction = Transaction(date: Date(), isConfirmed: false, userId: user.id!, paymentLink: transactionLink, amount: amount)
            try await transaction.save(on: req.db)

            // Check if the amount is fullVersionPrice
            if amount == fullVersionPrice {
                user.hasFullVersion = true
                try await user.save(on: req.db)
                return Response(status: .ok, body: .init(string: "Full version activated"))
            }
            
            let response = ["clientSecret": paymentIntent.clientSecret]
            
            print("Response: \(response)")

            return Response(status: .ok, body: .init(data: try JSONEncoder().encode(response)))
        } catch {
            print("Error creating payment sheet: \(error)")
            throw Abort(.internalServerError, reason: "Failed to create payment sheet: \(error.localizedDescription)")
        }
    }

    app.post("addToDb") { req -> String in
        //print JWT token from request
        let payload = try await req.jwt.verify(as: JWTModel.self)
        print(req.headers)
        print(payload.user)
        print(payload.email)
        return "dziala"
    }

    app.get("list-users") { req async throws -> Response in
        let users = try await User.query(on: req.db).all()
        return Response(status: .ok, body: .init(data: try JSONEncoder().encode(users)))
    }

    app.get("get-balance") { req async throws -> Response in
        let payload = try await req.jwt.verify(as: JWTModel.self)
        guard let user = try await User.query(on: req.db)
            .filter(\.$username == payload.user)
            .first() else {
            throw Abort(.notFound, reason: "User not found")
        }
        let response = ["balance": user.balance]
        return Response(status: .ok, body: .init(data: try JSONEncoder().encode(response)))
    }

    app.get("transaction-history") { req async throws -> Response in
        let payload = try await req.jwt.verify(as: JWTModel.self)
        let username = payload.user
        
        guard let user = try await User.query(on: req.db)
            .filter(\.$username == username)
            .with(\.$transactions) // Eager load transactions
            .first() else {
            throw Abort(.notFound, reason: "User not found")
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 3600) // Set to UTC+1
        
        // Fetch Bitcoin transactions
        let bitcoinTransactions = try await BitcoinTransaction.query(on: req.db)
            .filter(\.$username == username)
            .all()
        
        // Map user transactions to response
        let userTransactions = user.transactions.map { transaction in
            return TransactionHistoryResponse(
                date: dateFormatter.string(from: transaction.date),
                amount: Double(transaction.amount), // Convert to Double
                status: "confirmed", // Always set to "confirmed"
                type: "User"
            )
        }
        
        // Map Bitcoin transactions to response
        let bitcoinTransactionResponses = bitcoinTransactions.map { transaction in
            return TransactionHistoryResponse(
                date: dateFormatter.string(from: transaction.date),
                amount: Double(transaction.amount), // Convert to Double
                status: transaction.isConfirmed ? "confirmed" : "unconfirmed",
                type: "Bitcoin"
            )
        }
        
        // Combine both transaction responses
        let combinedTransactions = userTransactions + bitcoinTransactionResponses
        
        let jsonResponse = try JSONEncoder().encode(combinedTransactions)
        return Response(status: .ok, body: .init(data: jsonResponse))
    }

    app.get("play") { req async throws -> Response in
        let payload = try await req.jwt.verify(as: JWTModel.self)
        let username = payload.user

        guard let user = try await User.query(on: req.db)
            .filter(\.$username == username)
            .first() else {
            throw Abort(.notFound, reason: "User not found")
        }

        if user.hasFullVersion {
            // User has full version, allow unlimited moves
            return Response(status: .ok, body: .init(string: "You have unlimited moves!"))
        } else {
            // User does not have full version, check last play time
            let lastPlayTime = user.lastPlayTime ?? Date.distantPast
            let currentTime = Date()
            let timeInterval = currentTime.timeIntervalSince(lastPlayTime)

            if lastPlayTime == Date.distantPast || timeInterval >= 24 * 60 * 60 {
                // First play or more than 24 hours since last play, update last play time
                user.lastPlayTime = currentTime
                try await user.save(on: req.db)
                return Response(status: .ok, body: .init(string: "You can play!"))
            } else {
                // Less than 24 hours since last play
                return Response(status: .forbidden, body: .init(string: "You can only play once every 24 hours."))
            }
        }
    }

    app.post("purchase-full-version") { req async throws -> Response in
        let payload = try await req.jwt.verify(as: JWTModel.self)
        let username = payload.user

        guard let user = try await User.query(on: req.db)
            .filter(\.$username == username)
            .first() else {
            throw Abort(.notFound, reason: "User not found")
        }

        if user.balance < fullVersionPrice {
            return Response(status: .badRequest, body: .init(string: "Insufficient funds in balance"))
        }

        user.balance -= fullVersionPrice
        user.hasFullVersion = true
        try await user.save(on: req.db)
        return Response(status: .ok, body: .init(string: "Full version activated"))
    }

    struct TransactionHistoryResponse: Content {
        let date: String
        let amount: Double
        let status: String
        let type: String
    }

    app.post("place-unit") { req async throws -> Response in
        let payload = try await req.jwt.verify(as: JWTModel.self)
        guard let user = try await User.query(on: req.db)
            .filter(\.$username == payload.user)
            .first() else {
            throw Abort(.notFound, reason: "User not found")
        }
        //try req.content.decode([String: [Item]].self)["items"] ?? []
        let type = try req.content.decode([String: String].self)["type"] ?? ""

        var successfull = true
        if (type == "soldier" && (user.usedSoldiers < 300 || user.unlimitedUnits)) {
            user.usedSoldiers += 1
            try await user.save(on: req.db)
        } else if (type == "tank" && (user.usedTanks < 300 || user.unlimitedUnits)) {
            user.usedTanks += 1
            try await user.save(on: req.db)
        } else if (type == "plane" && (user.usedPlanes < 300 || user.unlimitedUnits)) {
            user.usedPlanes += 1
            try await user.save(on: req.db)
        } else {
            successfull = false
        }

        struct PlacedUnitResponse: Content {
            let successfull: Bool
            let usedSoldiers: Int
            let usedTanks: Int
            let usedPlanes: Int
        }

        let response = PlacedUnitResponse(
            successfull: successfull,
            usedSoldiers: user.usedSoldiers,
            usedTanks: user.usedTanks,
            usedPlanes: user.usedPlanes
        )
        return Response(status: .ok, body: .init(data: try JSONEncoder().encode(response)))
    }
}

func calculateOrderAmount(items: [Item]) -> Int {
    // Calculate the order total on the server to prevent
    // people from directly manipulating the amount on the client
    return items.reduce(0) { $0 + $1.amount }
}

struct Item: Content {
    let amount: Int
}

func updateUserBalance(username: String, amount: Int, on db: Database) async throws {
    guard let user = try await User.query(on: db)
        .filter(\.$username == username)
        .first() else {
        throw Abort(.notFound, reason: "User not found")
    }
    user.balance += amount
    try await user.save(on: db)
}
