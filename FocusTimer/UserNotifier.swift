import UserNotifications

class UserNotifier {
    enum Event {
        enum Mode {
            case busy
            case free
        }
        case start
        case swipe
        case drop
        case stop(Mode)
    }

    private var isEnabled = false
    private var isSoundEnabled = false

    init() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound],
            completionHandler: { response, _ in
                self.isEnabled = response
            }
        )
    }
}

extension UserNotifier{
    func handle(event: Event) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            self.isEnabled = (settings.authorizationStatus == .authorized)
            self.isSoundEnabled = (settings.soundSetting == .enabled)

            guard self.isEnabled else { return }

            switch event {
            case .start:
                self.play(sound: "Tink.aiff")
            case .swipe:
                self.play(sound: "Morse.aiff")
            case .drop:
                self.play(sound: "Pop.aiff")
            case .stop(let mode):
                self.play(sound: "Pop.aiff")

                let content = UNMutableNotificationContent()

                switch mode {
                case .busy:
                    content.title = "Work is done"
                    content.subtitle = "You can rest"
                case .free:
                    content.title = "Rest is over"
                    content.subtitle = "Get to work"
                }

                UNUserNotificationCenter.current().add(
                    UNNotificationRequest(
                        identifier: UUID().uuidString, content: content, trigger: nil
                    )
                )
            }
        }
    }

    private func play(sound: String) {
        guard
            isSoundEnabled,
            let path = Bundle.main.path(forResource: sound, ofType: nil),
            let sound = NSSound(contentsOfFile: path, byReference: true)
        else {
            return
        }
        sound.play()
    }
}

