import Foundation

typealias Completion = (() -> Void)

protocol PomodoroTimerInput: AnyObject {
    func toggle(completion: Completion?)
    func drop(completion: Completion?)
    func add(seconds: TimeInterval, completion: Completion?)
}

protocol PomodoroTimerOutput: AnyObject {
    func pomodoroTimerDidStart(_ timer: PomodoroTimer, mode: PomodoroTimer.Mode)
    func pomodoroTimerDidTick(_ timer: PomodoroTimer, seconds: TimeInterval)
    func pomodoroTimerDidEnd(_ timer: PomodoroTimer, mode: PomodoroTimer.Mode)
}

class PomodoroTimer {
    enum Mode: TimeInterval {
        case busy = 1500
        case free = 300
        case idle = 0
    }

    weak var delegate: PomodoroTimerOutput?

    private var mode: Mode = .idle {
        didSet {
            guard oldValue != mode else { return }
            isRunning = (mode != .idle)
            left = mode.rawValue
        }
    }

    private lazy var ticker: DispatchSourceTimer = {
        let timer = DispatchSource.makeTimerSource(flags: .strict, queue: .main)
        timer.schedule(deadline: .now(), repeating: .seconds(1), leeway: .milliseconds(100))
        timer.setEventHandler { [weak self] in self?.update() }
        return timer
    }()

    private var until: Date = .distantPast {
        didSet { update() }
    }

    private var left: TimeInterval {
        get { max(0, until.timeIntervalSinceNow).rounded() }
        set { until = max(Date(), Date().addingTimeInterval(newValue)) }
    }

    private var isRunning = false {
        didSet {
            guard oldValue != isRunning else { return }
            isRunning ? ticker.resume() : ticker.suspend()
        }
    }

    private var isAsleep = false

    init() {
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
    }

    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        ticker.setEventHandler { }
        ticker.cancel()
    }
}

extension PomodoroTimer {
    @objc
    private func willSleep() {
        isAsleep = isRunning
        isRunning = false
    }

    @objc
    private func didWake() {
        isRunning = isAsleep
        isAsleep = false
    }

    private func update() {
        guard mode != .idle else { return }

        if left == 0 {
            isRunning = false
            delegate?.pomodoroTimerDidEnd(self, mode: mode)
        } else {
            isRunning = true
            delegate?.pomodoroTimerDidTick(self, seconds: left)
        }
    }
}

extension PomodoroTimer: PomodoroTimerInput {
    func toggle(completion: Completion? = nil) {
        guard !isRunning else { return }
        mode = (mode != .busy) ? .busy : .free
        delegate?.pomodoroTimerDidStart(self, mode: mode)
        completion?()
    }

    func drop(completion: Completion? = nil) {
        mode = .idle
        delegate?.pomodoroTimerDidStart(self, mode: mode)
        completion?()
    }

    func add(seconds: TimeInterval, completion: Completion? = nil) {
        guard mode != .idle else { return }
        left += seconds
        completion?()
    }
}
