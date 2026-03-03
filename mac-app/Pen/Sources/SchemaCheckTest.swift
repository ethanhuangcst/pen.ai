import Foundation

@main
enum SchemaCheckTest {
    static func main() {
        print("=== Starting database schema check ===")
        
        // Run the schema checker
        Task {
            await DatabaseSchemaChecker.shared.checkAndUpdateSchema()
            print("\n=== Schema check completed ===")
            exit(0)
        }
        
        // Keep the process running until the task completes
        RunLoop.main.run()
    }
}
