import Foundation
import Workspace

public protocol Target {
    init?(configuration: Configuration) throws
    func createDestination(buildDirectory: String) throws -> Destination
}

public func createTarget(configuration: Configuration) throws -> Target {
    if let target = try STM32Target(configuration: configuration) {
        return target
    } else {
        let message = "The target \(configuration.target) is not supported."
        throw Error.unsupported(message: message)
    }
}
