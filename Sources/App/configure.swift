import Vapor
import Fluent
import FluentMongoDriver
import DotEnv
import StripeKit
import JWT

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

public func configure(_ app: Application) async throws {
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    let path = "./.env"
    let env = try DotEnv.read(path: path)
    env.lines 
    env.load()

    var logger = Logger(label: "vapor-logger")
    logger.logLevel = .trace

    let logLevel = Environment.get("LOG_LEVEL")
    
    if let logLevel, let logLevel = Logger.Level(rawValue: logLevel) {
        logger.logLevel = logLevel
    }
    
    guard let mongoUrl = ProcessInfo.processInfo.environment["MONGODB_URL"] else {
        throw Abort(.internalServerError, reason: "MONGODB_URL not set")
    }

    
    try app.databases.use(.mongo(connectionString: mongoUrl), as: .mongo)

    app.migrations.add(CreateUser())
    try await app.autoMigrate()

    app.stripe

    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    let clerkPK: String = """
    -----BEGIN PUBLIC KEY-----
    MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsAjc1Pt7Itp7BrEUzd2B
    sdo8Yv0/OTzI/4ZNsRfW1n5qaLBJg/ZsPmwlSRGOx2cN1Lk+5U8lHZYDSuoqSHGz
    kslvYAoMKtLEaI1PZqyQjFgVlvpa6m5PN52a6Cu5fnzliqm6LVVnn3H3ATFinCgh
    +loOH8yzB7gxn9DNFljLllnEqrrgvQD5g3c5yUHF5Pn6ZASBifNsc0RdBhrRMQ2j
    zbUxbNUggUBM9kJom2uFIlJQaPLjTg0yt8NCPkbiI0UquOowBN9N0QXBD34dIKTJ
    niFaRm9TWvyHVr+Q+nDL3ipas6xEjsTr+QxOj0FMTr2VfddB0FWTkaB1uTbyCiCo
    6wIDAQAB
    -----END PUBLIC KEY-----
    -----END PUBLIC KEY-----
    """ 

    // Initialize an RSA key with public pem.
    let key = try Insecure.RSA.PublicKey(pem: clerkPK)

    await app.jwt.keys.add(rsa: key, digestAlgorithm: .sha256)

    // register routes
    try routes(app)
}
