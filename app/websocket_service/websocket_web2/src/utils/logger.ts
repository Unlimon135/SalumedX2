//file: websocket_web2/src/utils/logger.ts
// Utility class for logging messages
export class Logger {
    static info(message: string): void {
    console.log(`[INFO] ${new Date().toISOString()} - ${message}`);
    }
// Logs a warning message with a timestamp
    static error(message: string): void {
    console.error(`[ERROR] ${new Date().toISOString()} - ${message}`);
    }
}
