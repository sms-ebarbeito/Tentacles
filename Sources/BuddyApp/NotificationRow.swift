import Cocoa
import BuddyCore

class NotificationRow: NSView {
    private let appLabel  = NSTextField(labelWithString: "")
    private let timeLabel = NSTextField(labelWithString: "")
    private let titleLabel = NSTextField(labelWithString: "")
    private let bodyLabel  = NSTextField(labelWithString: "")

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = NSColor.white.withAlphaComponent(0.06).cgColor
        layer?.cornerRadius = 6

        appLabel.font  = .systemFont(ofSize: 9, weight: .bold)
        appLabel.textColor = NSColor(red: 0.72, green: 0.45, blue: 0.95, alpha: 1)
        timeLabel.font = .systemFont(ofSize: 9)
        timeLabel.textColor = NSColor.white.withAlphaComponent(0.35)
        timeLabel.alignment = .right
        titleLabel.font = .systemFont(ofSize: 11, weight: .medium)
        titleLabel.textColor = .white
        titleLabel.lineBreakMode = .byTruncatingTail
        bodyLabel.font = .systemFont(ofSize: 10)
        bodyLabel.textColor = NSColor.white.withAlphaComponent(0.65)
        bodyLabel.maximumNumberOfLines = 2
        bodyLabel.lineBreakMode = .byTruncatingTail

        for v in [appLabel, timeLabel, titleLabel, bodyLabel] as [NSView] {
            v.translatesAutoresizingMaskIntoConstraints = false
            addSubview(v)
        }
        NSLayoutConstraint.activate([
            appLabel.topAnchor.constraint(equalTo: topAnchor, constant: 7),
            appLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 9),
            appLabel.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -4),

            timeLabel.topAnchor.constraint(equalTo: topAnchor, constant: 7),
            timeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -9),
            timeLabel.widthAnchor.constraint(equalToConstant: 44),

            titleLabel.topAnchor.constraint(equalTo: appLabel.bottomAnchor, constant: 2),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 9),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -9),

            bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 1),
            bodyLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 9),
            bodyLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -9),
            bodyLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -7),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(with n: AppNotification) {
        appLabel.stringValue = n.appName.uppercased()
        titleLabel.stringValue = n.title.isEmpty ? n.appName : n.title
        let text = [n.subtitle, n.body].filter { !$0.isEmpty }.joined(separator: " · ")
        bodyLabel.stringValue = text
        bodyLabel.isHidden = text.isEmpty

        let fmt = DateFormatter()
        fmt.dateFormat = Calendar.current.isDateInToday(n.date) ? "HH:mm" : "dd/MM"
        timeLabel.stringValue = fmt.string(from: n.date)
    }
}
