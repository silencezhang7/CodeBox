import Foundation
import UserNotifications
import CoreLocation
import ActivityKit
import MapKit

@MainActor
class ReminderManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = ReminderManager()
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func requestPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted.")
            }
        }
    }
    
    // MARK: - Live Activity
    func startLiveActivity(for item: ClipboardItem) {
        if #available(iOS 16.1, *) {
            guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
            
            let attributes = CodeBoxAttributes(itemId: item.id.uuidString)
            let initialContentState = CodeBoxAttributes.ContentState(
                pickupCode: item.content,
                stationName: item.stationName ?? "",
                platform: item.sourcePlatform ?? "",
                reminderText: item.reminderText
            )
            
            do {
                let activity = try Activity.request(
                    attributes: attributes,
                    content: .init(state: initialContentState, staleDate: nil)
                )
                item.liveActivityId = activity.id
            } catch {
                print("Failed to start Live Activity: \(error.localizedDescription)")
            }
        }
    }
    
    func stopLiveActivity(for item: ClipboardItem) {
        if #available(iOS 16.1, *) {
            guard let activityId = item.liveActivityId else { return }
            Task.detached {
                if let activity = Activity<CodeBoxAttributes>.activities.first(where: { $0.id == activityId }) {
                    await activity.end(nil, dismissalPolicy: .immediate)
                }
            }
        }
    }
    
    func updateLiveActivity(for item: ClipboardItem) {
        if #available(iOS 16.1, *) {
            guard let activityId = item.liveActivityId else { return }
            let updatedState = CodeBoxAttributes.ContentState(
                pickupCode: item.content,
                stationName: item.stationName ?? "",
                platform: item.sourcePlatform ?? "",
                reminderText: item.reminderText
            )
            Task.detached {
                if let activity = Activity<CodeBoxAttributes>.activities.first(where: { $0.id == activityId }) {
                    await activity.update(ActivityContent(state: updatedState, staleDate: nil))
                }
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let identifier = notification.request.identifier
        Task { @MainActor in
            self.handleNotificationTriggered(identifier: identifier)
        }
        completionHandler([.banner, .sound, .badge])
    }
    
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let identifier = response.notification.request.identifier
        Task { @MainActor in
            self.handleNotificationTriggered(identifier: identifier)
        }
        completionHandler()
    }
    
    private func handleNotificationTriggered(identifier: String) {
        if #available(iOS 16.1, *) {
            Task.detached {
                for activity in Activity<CodeBoxAttributes>.activities {
                    if activity.attributes.itemId == identifier {
                        let currentState = activity.content.state
                        let formatter = DateFormatter()
                        formatter.dateFormat = "MM-dd HH:mm"
                        let timeString = formatter.string(from: Date())
                        
                        let updatedState = CodeBoxAttributes.ContentState(
                            pickupCode: currentState.pickupCode,
                            stationName: currentState.stationName,
                            platform: currentState.platform,
                            reminderText: "已在 \(timeString) 提醒"
                        )
                        await activity.update(ActivityContent(state: updatedState, staleDate: nil))
                    }
                }
            }
        }
    }

    // MARK: - Notifications
    func scheduleReminder(for item: ClipboardItem) {
        removeReminder(for: item)
        
        guard !item.isUsed else { return }
        
        // Start live activity whenever a pending item is added or updated
        startLiveActivity(for: item)
        
        let content = UNMutableNotificationContent()
        content.title = "待取件提醒"
        content.body = "您有一个来自\(item.sourcePlatform ?? "未知")的包裹待取，取件码：\(item.content)"
        content.sound = .default
        
        let identifier = item.id.uuidString
        var trigger: UNNotificationTrigger?
        
        switch item.reminderType {
        case .default18:
            var dateComponents = DateComponents()
            dateComponents.hour = 18
            dateComponents.minute = 0
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        case .halfHour:
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 30 * 60, repeats: true)
        case .oneHour:
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60 * 60, repeats: true)
        case .daily:
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 24 * 60 * 60, repeats: true)
        case .exactTime:
            if let date = item.reminderTime {
                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
                trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            }
        }
        
        if let trigger = trigger {
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error)")
                }
            }
        }
    }
    
    func removeReminder(for item: ClipboardItem) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [item.id.uuidString])
        stopLiveActivity(for: item)
    }
    
}
