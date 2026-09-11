import Foundation

/// Generic loading state representing asynchronous resource fetching.
public enum LoadingState<Value: Equatable>: Equatable {
    case idle
    case loading
    case loaded(Value)
    case failed(String)

    /// Returns the wrapped value if loaded, nil otherwise.
    public var value: Value? {
        if case .loaded(let val) = self {
            return val
        }
        return nil
    }

    /// Whether the current state is loading.
    public var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }

    /// Whether the current state has successfully loaded.
    public var isLoaded: Bool {
        if case .loaded = self {
            return true
        }
        return false
    }

    /// Returns the error message if failed, nil otherwise.
    public var error: String? {
        if case .failed(let msg) = self {
            return msg
        }
        return nil
    }
}

extension LoadingState: Sendable where Value: Sendable {}
