import Foundation
import Network

@MainActor
class BuddyServer {
    static let port: UInt16 = 7878
    private var listener: NWListener?
    weak var controller: BuddyController?

    func start() {
        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true
        guard let listener = try? NWListener(using: params, on: NWEndpoint.Port(rawValue: Self.port)!) else {
            return
        }
        self.listener = listener
        listener.newConnectionHandler = { [weak self] conn in
            Task { @MainActor [weak self] in self?.handle(conn) }
        }
        listener.start(queue: .global(qos: .utility))
    }

    private func handle(_ conn: NWConnection) {
        conn.start(queue: .global(qos: .utility))
        conn.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, _ in
            defer {
                let resp = "HTTP/1.1 200 OK\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
                conn.send(content: resp.data(using: .utf8), completion: .contentProcessed { _ in conn.cancel() })
            }
            guard let data,
                  let body = Self.extractBody(from: data),
                  let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
                  let message = json["message"] as? String else { return }
            Task { @MainActor [weak self] in
                self?.controller?.showClaudeBubble(message: message)
            }
        }
    }

    nonisolated private static func extractBody(from data: Data) -> Data? {
        let sep = Data([0x0d, 0x0a, 0x0d, 0x0a])
        guard let range = data.range(of: sep) else { return nil }
        let body = data[range.upperBound...]
        return body.isEmpty ? nil : body
    }
}
