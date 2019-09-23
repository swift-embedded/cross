import Foundation

public enum Error: Swift.Error {
    case invalidConfiguration(reason: String)
    case unsupported(message: String)
    case dependencyNotFound(message: String)
    case subprocessFailed(exitStatus: Int, stderrOutput: String)
    case subprocessCommunicationFailure(message: String)
}
