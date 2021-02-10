import Cocoa

private extension NSTouchBarItem.Identifier {
    static let button = NSTouchBarItem.Identifier("com.aloshev.focustimer.button")
}

class PomodoroController: NSViewController {
    private lazy var button: TouchButton = {
        let button = TouchButton(
            image: NSImage(named: NSImage.Name("BarIcon"))!,
            target: nil,
            action: nil
        )
        button.font = NSFont.monospacedDigitSystemFont(ofSize: 15, weight: .medium)
        button.delegate = self
        return button
    }()

    // Some user activities (e.g. video watching) can displace the button out of the control strip
    private let occupier: DispatchSourceTimer = {
        let timer = DispatchSource.makeTimerSource(flags: .strict, queue: .main)
        timer.schedule(deadline: .now(), repeating: .seconds(1), leeway: .milliseconds(100))
        timer.setEventHandler { DFRElementSetControlStripPresenceForIdentifier(.button, true) }
        return timer
    }()

    private lazy var timer: PomodoroTimer = {
        let timer = PomodoroTimer()
        timer.delegate = self
        return timer
    }()

    private let notifier = UserNotifier()

    private let formatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()

    override func loadView() {
        view = NSView()

        let item = NSCustomTouchBarItem(identifier: .button)
        item.view = button

        NSTouchBarItem.addSystemTrayItem(item)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(willSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(didWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        occupier.resume()
    }

    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        occupier.setEventHandler { }
        occupier.cancel()
    }
}

extension PomodoroController {
    @objc
    private func willSleep() {
        occupier.suspend()
    }

    @objc
    private func didWake() {
        occupier.resume()
    }
}

extension PomodoroController: PomodoroTimerOutput {
    func pomodoroTimerDidStart(_ timer: PomodoroTimer, mode: PomodoroTimer.Mode) {
        switch mode {
        case .free:
            button.imagePosition = .noImage
            button.bezelColor = .systemGreen
        case .busy:
            button.imagePosition = .noImage
            button.bezelColor = .systemRed
        case .idle:
            button.imagePosition = .imageOnly
            button.bezelColor = .clear
            button.title = ""
        }
    }

    func pomodoroTimerDidTick(_ timer: PomodoroTimer, seconds: TimeInterval) {
        button.title = (formatter.string(from: seconds) ?? "")
    }

    func pomodoroTimerDidEnd(_ timer: PomodoroTimer, mode: PomodoroTimer.Mode) {
        button.title = "00:00"

        switch mode {
        case .busy: notifier.handle(event: .stop(.busy))
        case .free: notifier.handle(event: .stop(.free))
        case .idle: break
        }
    }
}

extension PomodoroController: TouchButtonDelegate {
    func tapTouchButton(_ button: TouchButton) {
        timer.toggle() { [weak notifier] in notifier?.handle(event: .start) }
    }

    func doubleTapTouchButton(_ button: TouchButton) {
        timer.drop() { [weak notifier] in notifier?.handle(event: .drop) }
    }

    func holdTouchButton(_ button: TouchButton) {
        exit(0)
    }

    func swipeLeftTouchButton(_ button: TouchButton) {
        timer.add(seconds: -300) { [weak notifier] in notifier?.handle(event: .swipe) }
    }

    func swipeRightTouchButton(_ button: TouchButton) {
        timer.add(seconds: 300) { [weak notifier] in notifier?.handle(event: .swipe) }
    }
}
