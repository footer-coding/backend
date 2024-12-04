import Vapor
import DotEnv
import StripeKit    

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

    app.post("create-payment-intent") { req async throws -> Response in
        let items = try req.content.decode([String: [Item]].self)["items"] ?? []
        
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
        
        let response = [
            "clientSecret": paymentIntent.clientSecret,
            "dpmCheckerLink": "https://dashboard.stripe.com/settings/payment_methods/review?transaction_id=\(paymentIntent.id)"
        ]
        
        return Response(status: .ok, body: .init(data: try JSONEncoder().encode(response)))

    }
    // app.post("verify") {req -> String in
    //     let user = try req.auth.require(JWTModel.self)

    //     print(user)

    //     return "dziala"
    // }

    app.post("addToDb") { req -> String in
        //print JWT token from request
        let payload = try await req.jwt.verify(as: JWTModel.self)
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

