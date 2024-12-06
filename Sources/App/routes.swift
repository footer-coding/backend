import Vapor
import DotEnv
import StripeKit
import Fluent 
import FluentMongoDriver// Add this import

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

    app.post("create-payment-intent") { req async throws -> Response in
        let items = try req.content.decode([String: [Item]].self)["items"] ?? []
        let payload = try await req.jwt.verify(as: JWTModel.self)
        let user = payload.user

        print(items)
        
        let amount = calculateOrderAmount(items: items)
        
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
        
        // Update user balance
        try await updateUserBalance(username: user, amount: amount, on: req.db)
        
        // Save transaction to database
        let transaction = Transaction(username: user, amount: amount, paymentIntentId: paymentIntent.id)
        try await transaction.save(on: req.db)
        
        let response = [
            "clientSecret": paymentIntent.clientSecret,
            "paymentIntent": paymentIntent.clientSecret,
            "dpmCheckerLink": "https://dashboard.stripe.com/settings/payment_methods/review?transaction_id=\(paymentIntent.id)"
        ]
        
        return Response(status: .ok, body: .init(data: try JSONEncoder().encode(response)))
    }

    app.post("create-payment-sheet") { req async throws -> Response in
        let items = try req.content.decode([String: [Item]].self)["items"] ?? []
        let payload = try await req.jwt.verify(as: JWTModel.self)
        let user = payload.user
        
        let amount = calculateOrderAmount(items: items)
        
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
        
        // Update user balance
        try await updateUserBalance(username: user, amount: amount, on: req.db)
        
        // Save transaction to database
        let transaction = Transaction(username: user, amount: amount, paymentIntentId: paymentIntent.id)
        try await transaction.save(on: req.db)
        
        let response = [
            "paymentIntent": paymentIntent.clientSecret
        ]
        
        return Response(status: .ok, body: .init(data: try JSONEncoder().encode(response)))
    }

    app.get("transactions-history") { req async throws -> Response in
        let payload = try await req.jwt.verify(as: JWTModel.self)
        let user = payload.user
        
        let transactions = try await Transaction.query(on: req.db)
            .filter(\.$username == user)
            .all()
        
        return Response(status: .ok, body: .init(data: try JSONEncoder().encode(transactions)))
    }

    app.get("all-transactions-history") { req async throws -> Response in
        let transactions = try await Transaction.query(on: req.db).all()
        
        return Response(status: .ok, body: .init(data: try JSONEncoder().encode(transactions)))
    }

    app.post("addToDb") { req -> String in
        //print JWT token from request
        let payload = try await req.jwt.verify(as: JWTModel.self)
        print(req.headers)
        print(payload.user)
        print(payload.email)
        return "dziala"
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

