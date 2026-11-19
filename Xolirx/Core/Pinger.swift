import Foundation
import Network

/// Честный TCP-пинг: время установления TCP-соединения до узла.
/// Без ядра измерить HTTPS через сам туннель нельзя, поэтому в интерфейсе
/// подписано именно «TCP», без выдуманных миллисекунд.
enum TCPPing {

    static func measure(host: String, port: Int, timeout: TimeInterval = 3.5) async -> Int? {
        guard port > 0, port <= 65535,
              let nwPort = NWEndpoint.Port(rawValue: UInt16(port)) else { return nil }

        return await withCheckedContinuation { (continuation: CheckedContinuation<Int?, Never>) in
            let queue = DispatchQueue(label: "org.xolirx.tcp-ping")
            let lock = NSLock()
            var finished = false
            let start = DispatchTime.now().uptimeNanoseconds
            let connection = NWConnection(host: NWEndpoint.Host(host), port: nwPort, using: .tcp)

            func finish(_ value: Int?) {
                lock.lock()
                if finished {
                    lock.unlock()
                    return
                }
                finished = true
                lock.unlock()
                connection.cancel()
                continuation.resume(returning: value)
            }

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    let elapsed = DispatchTime.now().uptimeNanoseconds - start
                    finish(Int(elapsed / 1_000_000))
                case .failed, .cancelled:
                    finish(nil)
                default:
                    break
                }
            }
            connection.start(queue: queue)
            queue.asyncAfter(deadline: .now() + timeout) { finish(nil) }
        }
    }
}
