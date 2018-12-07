import JWTVapor
import Command

func commands(config: inout CommandConfig)throws {
    let jwtCommand = NewJWTCommand {
        return User(
            exp: Date.distantFuture.timeIntervalSince1970,
            iat: Date().timeIntervalSince1970,
            email: "jwt.token@example.com",
            id: Int.random(in: 0...Int.max),
            status: .admin
        )
    }
    
    config.use(jwtCommand, as: "jwt")
}
