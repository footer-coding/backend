import JWTKit

struct JWTModel: JWTPayload {
    var exp: ExpirationClaim
    var sub: SubjectClaim

    // Możesz dodać inne pola, które będą w tokenie

    func verify(using algorithm: some JWTAlgorithm) async throws {
        try self.exp.verifyNotExpired()
    }
}