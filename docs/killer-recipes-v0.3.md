# Killer Recipes v0.3 (Implementation-Ready Catalog)

This catalog refines the proposed 20 recipes against current v0.3 constraints:

- Local-first execution only
- Sensitive actions require `user_initiated_required = true`
- Sensitive actions must run from `TriggerClass::UserInitiated`
- Capture requires visible UI proof token
- Cloud never executes recipes

## Distribution (Policy-Corrected)

- Standard: 8
- Sensitive: 12

Note: With current policy, any recipe touching camera/microphone/webcam/health is Sensitive.

## Desktop (8)

1) Smart Downloads Organizer  
- Trigger: `file.watcher` (Passive)  
- Actions: file extension route + move/rename  
- Permissions: `file.access`  
- Risk: Standard  
- v0.3 Status: Ready

2) Clipboard Regex Formatter  
- Trigger: `clipboard.change` (Passive)  
- Actions: transform text + `clipboard.write`  
- Permissions: `clipboard.read`, `clipboard.write`  
- Risk: Standard  
- v0.3 Status: Ready

3) Screenshot Rename + Move  
- Trigger: `file.watcher` (Passive)  
- Actions: timestamp rename + move  
- Permissions: `file.access`  
- Risk: Standard  
- v0.3 Status: Ready

4) Hotkey Work Mode Launcher  
- Trigger: `hotkey` (UserInitiated)  
- Actions: open URL + open workspace folder (app launch is v0.4 connector)  
- Permissions: `hotkey.register`, `network.request` (if needed)  
- Risk: Standard  
- v0.3 Status: Partial (without `app.launch`)

5) Meeting Audio Capture  
- Trigger: manual button (UserInitiated)  
- Actions: `microphone.record` + store `MediaRef`  
- Permissions: `microphone.record` (user-initiated only)  
- Risk: Sensitive  
- v0.3 Status: Ready

6) Webcam Snapshot to Clipboard  
- Trigger: hotkey (UserInitiated)  
- Actions: `webcam.capture` + `clipboard.write`  
- Permissions: `webcam.capture`, `clipboard.write`  
- Risk: Sensitive  
- v0.3 Status: Ready

7) OCR Capture Note  
- Trigger: manual (UserInitiated)  
- Actions: `camera.capture` + OCR transform + save text  
- Permissions: `camera.capture`, `file.access`  
- Risk: Sensitive  
- v0.3 Status: Partial (OCR plugin is v0.4)

8) Git Quick Pull (Allowlist)  
- Trigger: hotkey (UserInitiated)  
- Actions: local command execute allowlist (`git pull`)  
- Permissions: `hotkey.register`, `command.execute.allowlist`  
- Risk: Standard (or Restricted by enterprise policy)  
- v0.3 Status: v0.4 (command connector not in current MVP)

## Mobile (8)

9) Widget Tap Photo Memo  
- Trigger: widget tap (UserInitiated)  
- Actions: `camera.capture` + note text + save  
- Permissions: `camera.capture`, `file.access`  
- Risk: Sensitive  
- v0.3 Status: Ready

10) Voice Memo to TODO  
- Trigger: widget tap (UserInitiated)  
- Actions: `microphone.record` + speech-to-text + create TODO  
- Permissions: `microphone.record`  
- Risk: Sensitive  
- v0.3 Status: Partial (speech-to-text connector is v0.4)

11) Sleep Summary Morning Alert  
- Trigger: manual (UserInitiated, conservative default)  
- Actions: `health.read` (daily summary) + `notification.send`  
- Permissions: `health.read`, `notification.send`  
- Risk: Sensitive  
- v0.3 Status: Ready

12) Step Goal Reward Prompt  
- Trigger: manual check (UserInitiated)  
- Actions: `health.read` + conditional `notification.send`  
- Permissions: `health.read`, `notification.send`  
- Risk: Sensitive  
- v0.3 Status: Ready

13) Share Sheet URL Saver  
- Trigger: share sheet (UserInitiated)  
- Actions: parse URL/text + tag + store  
- Permissions: `file.access` (or local note store)  
- Risk: Standard  
- v0.3 Status: Ready

14) Capture to Project Sync Inbox  
- Trigger: manual (UserInitiated)  
- Actions: `camera.capture` + save + sync queue mark  
- Permissions: `camera.capture`, `file.access`  
- Risk: Sensitive  
- v0.3 Status: Ready

15) Pre-Meeting Focus Notification  
- Trigger: schedule (Passive)  
- Actions: `notification.send`  
- Permissions: `notification.send`  
- Risk: Standard  
- v0.3 Status: Ready

16) QR Capture and Open  
- Trigger: manual (UserInitiated)  
- Actions: `camera.capture` + QR decode + open URL  
- Permissions: `camera.capture`, `network.request` (optional validation ping)  
- Risk: Sensitive  
- v0.3 Status: Partial (QR decode transform is v0.4)

## Cross-device (4)

17) Desktop Screenshot to Mobile Push  
- Trigger: desktop file watcher (Passive)  
- Actions: relay metadata via `http.request` + mobile push relay  
- Permissions: `file.access`, `network.request`  
- Risk: Standard  
- v0.3 Status: Ready

18) Mobile Voice Idea to Desktop Note  
- Trigger: widget tap (UserInitiated)  
- Actions: `microphone.record` + save + sync  
- Permissions: `microphone.record`, `file.access`  
- Risk: Sensitive  
- v0.3 Status: Ready (transcription optional)

19) Receipt Capture to Expense CSV  
- Trigger: widget tap (UserInitiated)  
- Actions: `camera.capture` + OCR extract + CSV append  
- Permissions: `camera.capture`, `file.access`  
- Risk: Sensitive  
- v0.3 Status: Partial (OCR parser is v0.4)

20) Health-Aware Recovery Prompt  
- Trigger: manual (UserInitiated)  
- Actions: `health.read` + optional schedule context + recommendation notification  
- Permissions: `health.read`, `notification.send`  
- Risk: Sensitive  
- v0.3 Status: Ready (calendar connector is v0.4)

## Launch Recommendation

- Ship first public pack with 10 recipes: `1,2,3,5,6,9,11,13,15,17`.
- Keep OCR/STT/QR/command/calendar variants in “Labs” until their connectors are added.
- Marketplace policy:
  - Standard: automated checks + signature required
  - Sensitive: verified publisher + review required + explicit purpose text
