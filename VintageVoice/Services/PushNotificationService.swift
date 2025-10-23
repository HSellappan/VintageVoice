//
//  PushNotificationService.swift
//  VintageVoice
//
//  APNs and FCM push notification handling
//

import Foundation
import UserNotifications
import FirebaseMessaging

class PushNotificationService: NSObject, ObservableObject {
    @Published var fcmToken: String?
    @Published var notificationPermissionGranted = false

    static let shared = PushNotificationService()

    private override init() {
        super.init()
        Messaging.messaging().delegate = self
    }

    // MARK: - Permission

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.notificationPermissionGranted = granted
            }

            if granted {
                await registerForRemoteNotifications()
            }

            return granted
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }

    @MainActor
    private func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    // MARK: - Token Management

    func saveFCMToken(userID: String) async {
        guard let token = fcmToken else { return }

        do {
            // Save token to Firestore for server-side notifications
            let db = FirebaseManager.shared.db
            try await db.collection("users").document(userID).updateData([
                "fcmToken": token,
                "lastTokenUpdate": Timestamp(date: Date())
            ])
        } catch {
            print("Failed to save FCM token: \(error)")
        }
    }

    // MARK: - Handle Notifications

    func handleNotification(_ userInfo: [AnyHashable: Any]) {
        // Check notification type
        if let notificationType = userInfo["type"] as? String {
            switch notificationType {
            case "letter_delivered":
                handleLetterDelivered(userInfo)
            case "daily_spark":
                handleDailySpark(userInfo)
            default:
                print("Unknown notification type: \(notificationType)")
            }
        }
    }

    private func handleLetterDelivered(_ userInfo: [AnyHashable: Any]) {
        guard let letterID = userInfo["letterID"] as? String else { return }
        print("Letter delivered: \(letterID)")

        // Post notification for app to handle
        NotificationCenter.default.post(
            name: NSNotification.Name("LetterDelivered"),
            object: nil,
            userInfo: ["letterID": letterID]
        )
    }

    private func handleDailySpark(_ userInfo: [AnyHashable: Any]) {
        guard let promptID = userInfo["promptID"] as? String else { return }
        print("Daily Spark: \(promptID)")

        // Post notification for app to handle
        NotificationCenter.default.post(
            name: NSNotification.Name("DailySpark"),
            object: nil,
            userInfo: ["promptID": promptID]
        )
    }

    // MARK: - Schedule Local Notification (for testing)

    func scheduleLocalNotification(title: String, body: String, delay: TimeInterval = 5) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
}

// MARK: - MessagingDelegate

extension PushNotificationService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("FCM token: \(fcmToken ?? "nil")")
        self.fcmToken = fcmToken
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension PushNotificationService: UNUserNotificationCenterDelegate {
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        handleNotification(notification.request.content.userInfo)
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        handleNotification(response.notification.request.content.userInfo)
        completionHandler()
    }
}
