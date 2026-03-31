import SQLite3
import BuddyCore

class NotificationReader {
    private let dbPath: String
    private let parser = NotificationParser()
    private let filter = NotificationFilter()

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        dbPath = "\(home)/Library/Group Containers/group.com.apple.usernoted/db2/db"
    }

    func readActive() -> [AppNotification] {
        var db: OpaquePointer?
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_NOFOLLOW
        guard sqlite3_open_v2(dbPath, &db, flags, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_close(db) }

        let sql = """
            SELECT r.rec_id, a.identifier, r.data, r.delivered_date, r.presented
            FROM record r
            JOIN app a ON r.app_id = a.app_id
            WHERE r.presented = 1
               OR a.identifier IN ('com.apple.ical', 'com.apple.calendar')
            ORDER BY r.delivered_date DESC
            LIMIT 80
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }

        var results: [AppNotification] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let recId       = Int(sqlite3_column_int(stmt, 0))
            let bundleId    = String(cString: sqlite3_column_text(stmt, 1))
            let deliveredTs = sqlite3_column_double(stmt, 3)
            let presented   = sqlite3_column_int(stmt, 4)
            guard let dataPtr = sqlite3_column_blob(stmt, 2) else { continue }
            let data = Data(bytes: dataPtr, count: Int(sqlite3_column_bytes(stmt, 2)))
            if let n = parser.parse(data, recId: recId, bundleId: bundleId, ts: deliveredTs) {
                log("DB rec_id=\(recId) presented=\(presented) bundle=\(bundleId) titl=\(n.title) body=\(n.body.prefix(60))")
                if filter.passes(n) { results.append(n) }
            }
        }
        return results
    }
}
