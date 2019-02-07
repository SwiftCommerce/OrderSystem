import Vapor
import App

enum Result<Success, Failure: Error> {
    case success(Success)
    case failure(Failure)
    
    func get()throws -> Success {
        switch self {
        case let .success(result): return result
        case let .failure(error): throw error
        }
    }
}

struct AnyError: Error {
    let underlyingError: Error
    
    init(_ error: Error) {
        self.underlyingError = error
    }
}

extension Application {
    static func testable(env: Environment = .development) -> Result<Application, AnyError> {
        var services = Services.default()
        var config = Config.default()
        var env = env
        
        do {
            try configure(&config, &env, &services)
            let app = try Application(config: config, environment: env, services: services)
            
            return .success(app)
        } catch let error {
            return .failure(AnyError(error))
        }
    }
}
