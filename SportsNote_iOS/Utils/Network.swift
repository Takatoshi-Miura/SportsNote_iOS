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

    /// NWPathMonitorの初回パス確定を待ち合わせるための状態
    private let pathReadyState = NetworkPathReadyState()

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
            self.pathReadyState.markReady()
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

    /// NWPathMonitorの初回パス確定（初回コールバック到達）を待ち合わせる
    /// アプリ起動直後など、`isOnline()`の判定がNWPathMonitorの初回コールバックより先に
    /// 実行され、実際はオンラインでもデフォルト値`false`が返ってしまう問題を防ぐために使用する
    /// - Parameter timeout: 最大待機秒数。コールバックが到達しない異常系での保険（デフォルト2秒）
    static func waitForInitialPath(timeout: TimeInterval = 2.0) async {
        await shared.pathReadyState.waitUntilReady(timeout: timeout)
    }
}

/// `NWPathMonitor`の初回パス確定を待ち合わせるための状態管理クラス
/// `NWPathMonitor`そのものには依存せず、`markReady()`/`waitUntilReady(timeout:)`のみで構成されるため、
/// 単体テストでは`NWPathMonitor`を介さずにこのクラス単体を検証できる
final class NetworkPathReadyState: @unchecked Sendable {
    /// `CheckedContinuation`を一度だけresumeすることを保証するためのラッパー
    /// `markReady()`とタイムアウト処理が競合しても二重resumeによるクラッシュを防ぐ
    private final class ContinuationBox: @unchecked Sendable {
        private let continuation: CheckedContinuation<Void, Never>
        private let lock = NSLock()
        private var didResume = false

        init(_ continuation: CheckedContinuation<Void, Never>) {
            self.continuation = continuation
        }

        func resumeOnce() {
            lock.lock()
            defer { lock.unlock() }
            guard !didResume else { return }
            didResume = true
            continuation.resume()
        }
    }

    private let lock = NSLock()
    private var isReady = false
    private var pendingBoxes: [ContinuationBox] = []

    /// 初回パス確定を通知する（`NWPathMonitor`の`pathUpdateHandler`から呼ばれる想定）
    /// 2回目以降の呼び出しでは何もしない
    func markReady() {
        let boxes: [ContinuationBox] = {
            lock.lock()
            defer { lock.unlock() }
            guard !isReady else { return [] }
            isReady = true
            let boxes = pendingBoxes
            pendingBoxes.removeAll()
            return boxes
        }()

        boxes.forEach { $0.resumeOnce() }
    }

    /// 初回パス確定を待ち合わせる。既に確定済みの場合は即座に返る
    /// タイムアウトした場合も（コールバックが到達しない異常系向けの保険として）復帰する
    /// - Parameter timeout: 最大待機秒数
    func waitUntilReady(timeout: TimeInterval) async {
        if currentIsReady() {
            return
        }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let box = ContinuationBox(continuation)

            if registerIfNotReady(box) {
                // 登録前に既にready化されていた場合は即座にresumeする
                box.resumeOnce()
                return
            }

            DispatchQueue.global()
                .asyncAfter(deadline: .now() + timeout) { [weak self] in
                    guard let self = self else {
                        box.resumeOnce()
                        return
                    }
                    self.removePendingBox(box)
                    box.resumeOnce()
                }
        }
    }

    /// 現在のready状態を返す（同期処理としてロックを閉じ込めるためのヘルパー）
    private func currentIsReady() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return isReady
    }

    /// 未readyであれば`box`を待機リストに登録する
    /// - Returns: 登録時点で既にreadyだった場合はtrue（呼び出し元は即座にresumeする）
    private func registerIfNotReady(_ box: ContinuationBox) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if isReady {
            return true
        }
        pendingBoxes.append(box)
        return false
    }

    /// 待機リストから`box`を取り除く（タイムアウト到達時に呼ばれる）
    private func removePendingBox(_ box: ContinuationBox) {
        lock.lock()
        defer { lock.unlock() }
        if let index = pendingBoxes.firstIndex(where: { $0 === box }) {
            pendingBoxes.remove(at: index)
        }
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
