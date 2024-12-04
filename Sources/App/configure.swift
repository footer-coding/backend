import Vapor
import Fluent
import FluentMongoDriver
import DotEnv
import StripeKit

extension Application {
    public var stripe: StripeClient {
        guard let stripeKey = Environment.get("STRIPE_PV_KEY") else {
            fatalError("STRIPE_API_KEY env var required")
        }
        return .init(httpClient: self.http.client.shared, apiKey: stripeKey)
    }
}

extension Request {
    private struct StripeKey: StorageKey {
        typealias Value = StripeClient
    }
    
    public var stripe: StripeClient {
        if let existing = application.storage[StripeKey.self] {
            return existing
        } else {
            guard let stripeKey = Environment.get("STRIPE_PV_KEY") else {
                fatalError("STRIPE_API_KEY env var required")
            }
            let new = StripeClient(httpClient: self.application.http.client.shared, apiKey: stripeKey)
            self.application.storage[StripeKey.self] = new
            return new
        }
    }
}

extension StripeClient {
    /// Verifies a Stripe signature for a given `Request`. This automatically looks for the header in the headers of the request and the body.
    /// - Parameters:
    ///     - req: The `Request` object to check header and body for
    ///     - secret: The webhook secret used to verify the signature
    ///     - tolerance: In seconds the time difference tolerance to prevent replay attacks: Default 300 seconds
    /// - Throws: `StripeSignatureError`
    public static func verifySignature(for req: Request, secret: String, tolerance: Double = 300) throws {
        guard let header = req.headers.first(name: "Stripe-Signature") else {
            throw StripeSignatureError.unableToParseHeader
        }
        
        guard let data = req.body.data else {
            throw StripeSignatureError.noMatchingSignatureFound
        }
        
        try StripeClient.verifySignature(payload: Data(data.readableBytesView), header: header, secret: secret, tolerance: tolerance)
    }
}

extension StripeSignatureError: AbortError {
    public var reason: String {
        switch self {
        case .noMatchingSignatureFound:
            return "No matching signature was found"
        case .timestampNotTolerated:
            return "Timestamp was not tolerated"
        case .unableToParseHeader:
            return "Unable to parse Stripe-Signature header"
        }
    }
    
    public var status: HTTPResponseStatus {
        .badRequest
    }
}


// configures your application
public func configure(_ app: Application) async throws {

    let path = "./.env"
    let env = try DotEnv.read(path: path)
    env.lines 
    env.load()
    print(ProcessInfo.processInfo.environment["MONGODB_URL"]) 

    var logger = Logger(label: "vapor-logger")
    logger.logLevel = .trace

    let logLevel = Environment.get("LOG_LEVEL")
    
    if let logLevel, let logLevel = Logger.Level(rawValue: logLevel) {
        logger.logLevel = logLevel
    }
    
    guard let mongoUrl = Environment.get("MONGODB_URL") else {
        throw Abort(.internalServerError, reason: "MONGODB_URL not set")
    }
    
     try app.databases.use(.mongo(connectionString: mongoUrl), as: .mongo)

     app.stripe

     
     app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // register routes
    try routes(app)
}
