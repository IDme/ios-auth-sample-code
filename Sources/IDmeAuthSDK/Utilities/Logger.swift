import os

/// Internal logger wrapper using os.Logger.
enum Log {
    private static let logger = os.Logger(subsystem: "com.idme.auth-sdk", category: "IDmeAuthSDK")

    static func debug(_ message: String) {
        logger.debug("\(message, privacy: .public)")
    }

    static func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }

    static func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }
}
