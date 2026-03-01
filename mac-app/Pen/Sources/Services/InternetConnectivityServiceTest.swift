import Foundation

class InternetConnectivityServiceTest {
    // MARK: - Initialization
    init() {}
    
    // MARK: - Properties
    private let cacheDuration: TimeInterval = 10 // Cache results for 10 seconds
    private var lastCheckTime: TimeInterval = 0
    private var lastResult: Bool?
    
    // MARK: - Public Methods
    
    /// Checks if internet is available with default timeout
    func isInternetAvailable() -> Bool {
        return isInternetAvailable(timeout: 10.0) // Increased timeout to 10 seconds
    }
    
    /// Checks if internet is available with specified timeout
    func isInternetAvailable(timeout: TimeInterval) -> Bool {
        // Check if we can use cached result
        let currentTime = Date.timeIntervalSinceReferenceDate
        if let result = lastResult, currentTime - lastCheckTime < cacheDuration {
            return result
        }
        
        // Test actual internet connectivity on a background thread
        let semaphore = DispatchSemaphore(value: 0)
        var isConnected = false
        
        DispatchQueue.global(qos: .background).async {
            isConnected = self.testInternetConnectivity(timeout: timeout)
            semaphore.signal()
        }
        
        // Wait for task to complete or timeout
        let timeoutResult = semaphore.wait(timeout: .now() + timeout + 1.0) // Add 1 second buffer
        
        if timeoutResult == .timedOut {
            self.logError("Connectivity test timed out after \(timeout) seconds")
            return false
        }
        
        // Update cache
        lastResult = isConnected
        lastCheckTime = currentTime
        
        return isConnected
    }
    
    // MARK: - Private Methods
    
    /// Tests actual internet connectivity
    private func testInternetConnectivity(timeout: TimeInterval) -> Bool {
        let semaphore = DispatchSemaphore(value: 0)
        var isConnected = false
        
        // Create URL for connectivity test
        guard let url = URL(string: "https://www.apple.com") else {
            logError("Invalid URL for connectivity test")
            return false
        }
        
        // Create URL session configuration with timeout
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeout
        
        // Create URL session
        let session = URLSession(configuration: configuration)
        
        // Create data task
        let task = session.dataTask(with: url) { (_, response, error) in
            defer { semaphore.signal() }
            
            if let error = error {
                self.logError("Connectivity test failed: \(error.localizedDescription)")
                isConnected = false
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                isConnected = true
            } else {
                isConnected = false
            }
        }
        
        // Start task
        task.resume()
        
        // Wait for task to complete or timeout
        let timeoutResult = semaphore.wait(timeout: .now() + timeout)
        
        if timeoutResult == .timedOut {
            logError("Connectivity test timed out after \(timeout) seconds")
            task.cancel()
            return false
        }
        
        return isConnected
    }
    
    /// Logs errors
    private func logError(_ message: String) {
        print("[InternetConnectivityServiceTest] Error: \(message)")
    }
}
