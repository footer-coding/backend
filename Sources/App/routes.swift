import Vapor
import JWT

func routes(_ app: Application) throws {
    app.get { req async in
        "It works! dupa"
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
