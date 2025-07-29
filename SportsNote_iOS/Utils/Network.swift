import Foundation
import Network

/// ネットワーク接続状態を管理するクラス
final class Network: Sendable {
    /// 共有インスタンス
    static let shared = Network()

    /// ネットワーク接続状態監視
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")

    /// 現在のネットワーク接続状態（アトミックにアクセスするための値）
    private let _isConnected = AtomicValue<Bool>(initialValue: false)

    /// 現在のネットワーク接続状態（読み取り専用）
    var isConnected: Bool {
        return _isConnected.value
    }

    /// イニシャライザ
    private init() {
        startMonitoring()
    }

    /// デイニシャライザ
    deinit {
        stopMonitoring()
    }

    /// ネットワーク接続状態監視を開始
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let isConnected = path.status == .satisfied
            self._isConnected.value = isConnected
        }
        monitor.start(queue: monitorQueue)
    }

    /// ネットワーク接続状態監視を停止
    private func stopMonitoring() {
        monitor.cancel()
    }

    /// ネットワーク接続状態を返す
    /// - Returns: ネットワークが利用可能な場合はtrue
    static func isOnline() -> Bool {
        return shared.isConnected
    }
}

/// スレッドセーフな値へのアクセスを提供するクラス
final class AtomicValue<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: T

    /// 値の読み取り/書き込み（スレッドセーフ）
    var value: T {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _value
        }
        set {
            lock.lock()
            _value = newValue
            lock.unlock()
        }
    }

    /// イニシャライザ
    /// - Parameter initialValue: 初期値
    init(initialValue: T) {
        self._value = initialValue
    }
}
