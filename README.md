# Ambient Social Battery

**Ambient Social Battery** is an ambient, background-first iOS application built with SwiftUI, HealthKit, CoreML, and App Intents. The app monitors user physiological indicators (HRV SDNN and step count) in the background to detect social fatigue and proactively suggest recharge breaks via time-sensitive notifications and system shortcuts.

---

## 🏗 Key System Architecture & Constraints

1. **Event-Driven Background Processing**:
   - Operates without continuous background loops or timers.
   - Uses HealthKit's `HKObserverQuery` background delivery (`.immediate` frequency) to wake the app when fresh metric samples arrive.

2. **Strict Health Data Privacy**:
   - Raw HealthKit data (HRV values and step counts) is **never cached or stored** on disk or in `UserDefaults`.
   - Only the computed overload state boolean (`isOverloaded: Bool`) is stored, complying strictly with Apple's HealthKit Privacy Guidelines.

3. **App Group Shared State**:
   - State is shared safely between the main application and background extension targets using `SharedStateManager` powered by `UserDefaults(suiteName: "group.com.yourdomain.ambientbattery")`.
   - Includes automatic state validation: stored state automatically expires after **4 hours**.

4. **Performance Constraint**:
   - The entire background execution pipeline (sample ingestion → classification inference → state persistence) completes in **under 2 seconds**.

---

## 📁 Directory & Module Structure

```text
AmbientApp/
├── App/
│   ├── AmbientBatteryApp.swift     # Main app entry point
│   ├── AppDelegate.swift           # Handles HKObserverQuery background wakes
├── Core/
│   ├── State/
│   │   ├── SharedStateManager.swift # Thread-safe App Group UserDefaults manager
│   ├── Permissions/
│   │   ├── PermissionManager.swift  # Coordinates HealthKit & Notification authorizations
├── Services/
│   ├── HealthKit/
│   │   ├── HealthKitManager.swift   # Manages HealthKit authorization, queries & sample fetching
│   ├── MachineLearning/
│   │   ├── BatteryClassifier.swift  # CoreML wrapper & mock classification engine
│   ├── Notifications/
│   │   ├── NotificationEngine.swift # Dispatches Time-Sensitive local push alerts & action buttons
├── Intents/
│   ├── EnableRechargeIntent.swift   # AppIntent conforming action for Siri/Shortcuts/Notifications
├── UI/
│   ├── Onboarding/
│   │   ├── PermissionView.swift     # Explanatory onboarding UI prior to privacy prompts
│   ├── Dashboard/
│   │   ├── AmbientDashboardView.swift # Main UI displaying social battery status & validity
```

---

## ⚙️ Prerequisites & Xcode Target Setup

### 1. App Group Entitlement
1. Select the **`AmbientApp`** target in Xcode.
2. Go to **Signing & Capabilities** > **+ Capability** > **App Groups**.
3. Add container identifier: `group.com.yourdomain.ambientbattery`.

### 2. HealthKit Capability & Background Modes
1. Under **Signing & Capabilities**, add **HealthKit**.
2. Add **Background Modes** and check **Background fetch** and **Remote notifications** (if using push triggers).

### 3. Info.plist Privacy Keys
Ensure the following keys are present in your target's `Info.plist` (or Target Info settings):

```xml
<key>NSHealthShareUsageDescription</key>
<string>Ambient Social Battery analyzes HRV and activity data locally to detect social fatigue.</string>
<key>NSHealthUpdateUsageDescription</key>
<string>Ambient Social Battery updates health metrics related to social battery tracking.</string>
```

---

## 🧪 Testing & Injecting CoreML Models

- **Out-of-the-Box Mock Classifier**:
  The project includes `MockBatteryClassifier`, which evaluates HRV SDNN (< 40ms) and activity levels (> 7,500 steps) with random variance for instant testability without a trained model.

- **Injecting a Trained `.mlmodel`**:
  To swap in a production CoreML model:
  1. Add your `.mlmodel` or `.mlmodelc` file to the Xcode project.
  2. Implement `ClassifierEngine` in a custom struct/class wrapping your generated `MLModel` class.
  3. Initialize `BatteryClassifier(engine: YourRealMLClassifier())`.

---

## 🚀 Building & Running

1. Open `Untitled Project.xcodeproj` in Xcode 15+.
2. Select target **AmbientApp** and choose an iOS Simulator or physical iOS device running **iOS 17.0+**.
3. Build & Run (`⌘ R`).
