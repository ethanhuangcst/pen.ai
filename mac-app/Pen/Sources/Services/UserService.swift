import Foundation

class UserService {
    static let shared = UserService()
    
    private var _currentUser: User?
    private var _isLoggedIn: Bool = false
    private var _isOnline: Bool = true
    
    private init() {
        // Initialize with default values
        // In a real implementation, this would load from storage
    }
    
    // MARK: - Properties
    
    var currentUser: User? {
        get {
            return _currentUser
        }
        set {
            _currentUser = newValue
            _isLoggedIn = newValue != nil
        }
    }
    
    var isLoggedIn: Bool {
        return _isLoggedIn
    }
    
    var isOnline: Bool {
        return _isOnline
    }
    
    // MARK: - Methods
    
    func login(user: User) {
        _currentUser = user
        _isLoggedIn = true
        _isOnline = true
    }
    
    func logout() {
        _currentUser = nil
        _isLoggedIn = false
        _isOnline = true
    }
    
    func setOnlineStatus(_ online: Bool) {
        _isOnline = online
    }
}
