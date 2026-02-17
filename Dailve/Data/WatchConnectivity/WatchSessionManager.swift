import Foundation
@preconcurrency import WatchConnectivity
import Observation

/// Manages WatchConnectivity session for syncing workout data with Apple Watch
@Observable
@MainActor
final class WatchSessionManager: NSObject {
    static let shared = WatchSessionManager()

    private(set) var isReachable = false
    private(set) var isPaired = false
    private(set) var isWatchAppInstalled = false

    /// Latest workout data received from Watch
    private(set) var receivedWorkoutUpdate: WatchWorkoutUpdate?

    /// Callback for when Watch sends a completed workout
    var onWorkoutReceived: ((WatchWorkoutUpdate) -> Void)?

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else {
            AppLogger.ui.info("WatchConnectivity not supported on this device")
            return
        }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    /// Send current workout state to Watch for display
    func sendWorkoutState(_ state: WatchWorkoutState) {
        guard WCSession.default.isReachable else { return }

        do {
            let data = try JSONEncoder().encode(state)
            let message: [String: Any] = ["workoutState": data]
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                AppLogger.ui.error("Failed to send workout state to Watch: \(error.localizedDescription)")
            }
        } catch {
            AppLogger.ui.error("Failed to encode workout state: \(error.localizedDescription)")
        }
    }

    /// Send exercise library subset to Watch for offline use
    func transferExerciseLibrary(_ exercises: [WatchExerciseInfo]) {
        guard WCSession.default.activationState == .activated else { return }

        do {
            let data = try JSONEncoder().encode(exercises)
            let context: [String: Any] = ["exerciseLibrary": data]
            try WCSession.default.updateApplicationContext(context)
        } catch {
            AppLogger.ui.error("Failed to transfer exercise library: \(error.localizedDescription)")
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchSessionManager: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            isPaired = session.isPaired
            isWatchAppInstalled = session.isWatchAppInstalled
            if let error {
                AppLogger.ui.error("WCSession activation failed: \(error.localizedDescription)")
            }
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        // Required for iOS
    }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // Reactivate after deactivation (e.g., watch switch)
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isReachable = session.isReachable
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        let messageCopy = message.compactMapValues { $0 as? Data }
        Task { @MainActor in
            handleDecodedMessage(messageCopy)
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        let messageCopy = message.compactMapValues { $0 as? Data }
        replyHandler(["status": "received"])
        Task { @MainActor in
            handleDecodedMessage(messageCopy)
        }
    }
}

// MARK: - Message Handling

extension WatchSessionManager {
    private func handleDecodedMessage(_ message: [String: Data]) {
        // Handle workout completion from Watch
        if let data = message["workoutComplete"] {
            do {
                let update = try JSONDecoder().decode(WatchWorkoutUpdate.self, from: data)
                receivedWorkoutUpdate = update
                onWorkoutReceived?(update)
            } catch {
                AppLogger.ui.error("Failed to decode Watch workout: \(error.localizedDescription)")
            }
        }

        // Handle set completion from Watch
        if let data = message["setCompleted"] {
            do {
                let update = try JSONDecoder().decode(WatchWorkoutUpdate.self, from: data)
                receivedWorkoutUpdate = update
            } catch {
                AppLogger.ui.error("Failed to decode Watch set update: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Data Transfer Objects

/// Workout state sent from iPhone to Watch
struct WatchWorkoutState: Codable, Sendable {
    let exerciseName: String
    let exerciseID: String
    let currentSet: Int
    let totalSets: Int
    let targetWeight: Double?
    let targetReps: Int?
    let isActive: Bool
}

/// Workout data received from Watch
struct WatchWorkoutUpdate: Codable, Sendable {
    let exerciseID: String
    let exerciseName: String
    let completedSets: [WatchSetData]
    let startTime: Date
    let endTime: Date?
    let heartRateSamples: [WatchHeartRateSample]
}

struct WatchSetData: Codable, Sendable {
    let setNumber: Int
    let weight: Double?
    let reps: Int?
    let duration: TimeInterval?
    let isCompleted: Bool
}

struct WatchHeartRateSample: Codable, Sendable {
    let bpm: Double
    let timestamp: Date
}

/// Compact exercise info for Watch display
struct WatchExerciseInfo: Codable, Sendable {
    let id: String
    let name: String
    let inputType: String  // rawValue of ExerciseInputType
    let defaultSets: Int
    let defaultReps: Int?
}
