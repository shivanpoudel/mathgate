# MathGate

An original, deliberately plain iPhone mental-math gate, inspired by the interaction style of Zetamac. This project does not contain Zetamac source code, artwork, or branding. Project name: MathGate.

## Main app and settings

The home screen has a central Block button and a Settings gear in the top right. In the full build, Block requests Screen Time access if necessary, directs you to app selection when no apps are selected, and enables blocking when ready. The Blocked state lets you turn blocking off with confirmation. During an access window the central button becomes Block again. Solve to unlock opens the existing ten-question flow. Practice math is always available, but a practice round never grants access to blocked apps.

The MathGatePractice scheme previews this same main app and settings. Its Block button explains the physical-device requirement and never claims that apps are blocked. Use Practice math to test question generation and the keypad.

Settings include System/Light/Dark appearance, four operation toggles, configurable number ranges from 1 to 999, app selection in the full build, instructions, a local-data privacy explanation, version information, and reset math settings. Changes persist locally and take effect on the next round. At least one operation remains enabled. Appearance applies to the app, settings, and math screens; the system shield keeps its existing plain light design in this iteration. Questions per unlock and the 15-minute window remain fixed. No adaptive model or automatic difficulty change is implemented.

## Current behavior

Select individual apps, turn blocking on, and open one of those apps. Apple's shield offers “Solve questions,” which opens MathGate. Start the round and type ten correct answers. Correct answers advance automatically, with no multiple choice and no submit button. Wrong answers leave the current question in place. Subtraction stays positive and division has integer results. Default addition operands are 2–100 and multiplication uses 2–12 by 2–100. Settings can change these ranges and enabled operations. Subtraction and division use those generated pairs in reverse to preserve positive, integer answers.

A completed round lifts restrictions on ALL selected apps for 15 minutes. Return to the desired app yourself. A Device Activity extension restores the block at the end, even when the main app is not open. This is an access-window MVP, not an every-launch interceptor: exiting and reopening Instagram inside the window does not require another round. Apple's scheduled callbacks are system-managed, so precise timing and background reliability must be tested on your device. The 15-minute choice matches the documented minimum Device Activity monitoring interval.

This is voluntary self-control software. You can turn blocking off in the app or revoke authorization in Settings. It is not tamper-proof parental control. There is no server, analytics, account, ML model, or network request in the app. Selected application tokens and window state are stored locally in the shared App Group.

## First run on your Mac

Install Xcode from Apple and launch it once to finish installing its components. Use a version of Xcode that supports your connected iPhone's iOS version. The full MathGate scheme requires an SDK containing `ShieldActionResponse.openParentalControlsApp`, introduced in iOS 26.5. Merely changing the deployment target will not add that API to an older SDK.

Unzip this project and double-click `MathGate.xcodeproj`. No Homebrew, CocoaPods, Node, or XcodeGen is required. Keep this entire folder together. Open the same folder in VS Code when you want to edit the Swift source; use Xcode to build, sign, install, and debug the app.

For the quickest first look, select the **MathGatePractice** scheme in Xcode's toolbar and an iPhone simulator as the destination, then press Command-R. This scheme runs the real ten-question UI, but cannot block apps. It has no Screen Time or App Group entitlements and targets iOS 17 or later.

To put the practice app on your physical iPhone, connect it to your Mac, trust the computer, select the phone as Xcode's destination, and select your Apple account's Team under the MathGatePractice target's Signing & Capabilities. Enable Developer Mode on the phone if Xcode requests it. A personal development signing setup can be used for the practice target; provisioning and renewal limits are Apple's. If the bundle identifier is unavailable, change only that target's identifier to a unique value.

## Enable real blocking

The full **MathGate** target uses Apple's Family Controls capability, available through the Apple Developer Program for development. A free Personal Team that can run the practice target is not equivalent to having Family Controls provisioning. Check your developer membership and Xcode capability availability before paying for anything. Distribution through TestFlight or the App Store additionally requires Apple's Family Controls distribution entitlement approval for the app and its Screen Time extensions.

Select your developer Team under Signing & Capabilities for **MathGate**, **MathGateMonitor**, **MathGateShield**, and **MathGateAction**. Each must have Family Controls and the identical App Group `group.com.shivanpoudel.mathgate`. Register/enable that group for your team through Xcode or the developer account. If this identifier is unavailable, replace it in `Shared/GateState.swift` and all four `.entitlements` files. If you change the app's bundle identifier, keep the extension bundle identifiers prefixed by the new main app bundle identifier. Do not add these capabilities to MathGatePractice.

Choose the **MathGate** scheme, select your physical iPhone, and run. Approve Screen Time access in the app. Choose individual apps by expanding categories in the picker, save, and turn blocking on. Categories and websites themselves are intentionally excluded from this first version. Open Instagram, press “Solve questions,” start the round, and complete ten questions. Return to Instagram after success. All apps you selected share the same access window.

## Validation status and first device check

The earlier practice interface was built and tried in the user’s iPhone simulator. This main-app/settings revision has not been compiled or run in the delivery environment, which lacks Xcode, a Swift toolchain, and an attached iPhone. Structural checks are not a simulator or device test. The full Screen Time workflow remains unverified on hardware. Send back the first compiler or provisioning error if Xcode reports one.

After installing, verify that cancelling or giving wrong answers leaves Instagram blocked, and that the tenth correct answer grants access. Verify that it reblocks after 15 minutes with MathGate closed, not just while MathGate is in the foreground. Repeat after a phone restart, across midnight, and after changing the phone's time or timezone before relying on the blocker daily. Test revoking and restoring Screen Time authorization. Failed schedule creation should display an error and leave the shield in place. Selecting different apps or tapping “block again now” cancels the current window and blocks immediately. Background scheduling can be delayed by iOS; reopening MathGate reconciles expired state.

For this revision, check that the central Block button in the practice build shows an honest preview notice. Change each appearance mode and reopen the app to verify persistence. Enable just Division and confirm all practice questions are division with integer results; try a fixed factor range of 1–1 to verify a round still completes. Reset math settings and confirm blocking choices are untouched. Check that cancelling practice does not grant access, and that only the full build's unlock challenge can do so. In the simulator, enable I/O > Keyboard > Toggle Software Keyboard to see the numeric keypad.

Core arithmetic tests can run on your Mac from this folder with:

```sh
swift test
```

A simulator build of the practice scheme can be checked from Terminal with:

```sh
xcodebuild -project MathGate.xcodeproj -scheme MathGatePractice -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

## GitHub and VS Code

The project lives at https://github.com/shivanpoudel/mathgate. To work on it locally, open VS Code, press Command-Shift-P, choose **Git: Clone**, and paste that repository URL. Choose a local folder, authenticate through your usual GitHub account if prompted, and open the cloned folder. Alternatively, after installing Xcode's command-line tools, run:

```sh
git clone https://github.com/shivanpoudel/mathgate.git
cd mathgate
open MathGate.xcodeproj
```

Edit Swift files in VS Code and build/run the same checkout in Xcode. Save your edits, inspect the diff in VS Code's Source Control view, commit them, and sync to GitHub. Pull remote changes before beginning a new editing session. Do not initialize a second repository inside this clone or upload signing certificates, provisioning profiles, or secrets. No license has been chosen on your behalf.

## Where to make changes

`Core/Arithmetic.swift` defines the problem generation and ten-answer gate. `App/ContentView.swift` defines the home screen and routes practice versus unlock sessions. `App/ChallengeView.swift` owns the existing typed-answer flow. `App/SettingsView.swift` contains settings, and `App/Preferences.swift` persists appearance and math choices. `App/Blocker.swift` owns authorization and access scheduling. `Shared/GateState.swift` shares the selected apps and deadline with the monitor. `Shield` and `Action` define the system blocking screen and its buttons. `Monitor` restores restrictions when the scheduled access interval ends. `Tests` covers the arithmetic and challenge completion logic.

The included Xcode project is ready to open. `scripts/generate_project.py` is an optional, dependency-free generator used to create it. Running that script again overwrites project settings, including changes made in Xcode, so do not rerun it casually after configuring signing. New Swift files must be added to the appropriate target membership in Xcode, not merely created in VS Code.

Keep session history and adaptive question selection for later iterations. A future adaptive scheduler could first adjust ranges using accuracy and response time; an ML model is optional, not necessary to make difficulty progressive. The current generator remains random and applies the same chosen settings for the entire round.

## Apple references

[Configuring Family Controls](https://developer.apple.com/documentation/xcode/configuring-family-controls), [opening the controlling app from a shield](https://developer.apple.com/documentation/managedsettings/shieldactionresponse/openparentalcontrolsapp), [minimum monitoring interval](https://developer.apple.com/documentation/deviceactivity/deviceactivitycenter/monitoringerror/intervaltooshort), and [distribution entitlement requests](https://developer.apple.com/documentation/familycontrols/requesting-the-family-controls-entitlement).
