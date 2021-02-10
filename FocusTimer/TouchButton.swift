import Cocoa

protocol TouchButtonDelegate: AnyObject {
    func tapTouchButton(_ button: TouchButton)
    func doubleTapTouchButton(_ button: TouchButton)
    func holdTouchButton(_ button: TouchButton)
    func swipeLeftTouchButton(_ button: TouchButton)
    func swipeRightTouchButton(_ button: TouchButton)
}

extension TouchButtonDelegate {
    func tapTouchButton(_ button: TouchButton) { }
    func doubleTapTouchButton(_ button: TouchButton) { }
    func holdTouchButton(_ button: TouchButton) { }
    func swipeLeftTouchButton(_ button: TouchButton) { }
    func swipeRightTouchButton(_ button: TouchButton) { }
}

class TouchButton: NSButton {
    weak var delegate: TouchButtonDelegate?

    var tapThreshold: TimeInterval = 0.25
    var holdThreshold: TimeInterval = 0.5
    var swipeThreshold: CGFloat = 10

    private lazy var timer: DispatchSourceTimer = {
        let timer = DispatchSource.makeTimerSource(queue: .main)

        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            self.delegate?.holdTouchButton(self)
            self.resetButton()
        }

        return timer
    }()

    private var isTimerRunning = false {
        didSet {
            guard oldValue != isTimerRunning else { return }
            isTimerRunning ? timer.resume() : timer.suspend()
        }
    }

    private var touchPoint: CGPoint = .zero
    private var touchTime: TimeInterval = 0

    deinit {
        timer.setEventHandler { }
        timer.cancel()
    }
}

extension TouchButton {
    override func touchesBegan(with event: NSEvent) {
        guard let touch = event.touches(matching: .began, in: self).first else { return }

        touchPoint = touch.location(in: self)
        resetTimer()

        super.touchesBegan(with: event)
    }

    override func touchesEnded(with event: NSEvent) {
        guard let touch = event.touches(matching: .ended, in: self).first else { return }

        isTimerRunning = false

        let prevTouchTime = touchTime
        let prevTouchPoint = touchPoint

        touchTime = Date().timeIntervalSince1970
        touchPoint = touch.location(in: self)

        let distance = touchPoint.x - prevTouchPoint.x
        let period = touchTime - prevTouchTime

        switch (distance, period) {
        case (...(-swipeThreshold), _):
            delegate?.swipeLeftTouchButton(self)
            resetButton()
        case (swipeThreshold..., _):
            delegate?.swipeRightTouchButton(self)
            resetButton()
        case (_, ...tapThreshold):
            delegate?.doubleTapTouchButton(self)
            resetButton()
        case (_, tapThreshold...):
            delegate?.tapTouchButton(self)
        default:
            break
        }

        super.touchesEnded(with: event)
    }

    override func touchesCancelled(with event: NSEvent) {
        resetButton()
        super.touchesCancelled(with: event)
    }
}

extension TouchButton {
    private func resetTimer() {
        isTimerRunning = false
        timer.schedule(deadline: .now() + holdThreshold)
        isTimerRunning = true
    }

    private func resetButton() {
        touchPoint = .zero
        touchTime = 0
        isTimerRunning = false
    }
}
