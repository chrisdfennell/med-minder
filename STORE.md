# Connect IQ Store listing

Copy for the [Connect IQ developer portal](https://apps.garmin.com/en-US/developer/dashboard) listing, plus the pre-publish checklist.

## App name
MedMinder

## Short description (one line)
Track your daily doses and keep a tidy list of your medications.

## Full description
MedMinder turns your Garmin watch into a simple medication tracker and medicine list.

TODAY
• See today's doses grouped by time.
• Tap (or press START) to mark a dose taken — or "Take all" a whole time slot or the entire day at once.
• Build an adherence streak for every day you take everything that's due.
• A glance shows your next dose and streak one swipe from the watch face.

MEDICINE LIST
• Keep a clean catalog of everything you take — name, dose, and frequency.
• Type a frequency like "3x a day", or let MedMinder fill it in from your schedule.
• Add "as needed" meds with no set times — they're listed without daily reminders.
• Tap any med for full details: dose, frequency, times, and which days.

ADD YOUR MEDS
• Open MedMinder's settings in the Garmin Connect app and fill in any of 18 medication slots — each its own collapsible section with name, dose, days, and up to four daily reminder times from dropdown pickers.
• Works with both buttons and touchscreens, on round MIP and AMOLED watches.

Not a medical device. MedMinder helps you remember and record doses; always follow your prescriber's and pharmacist's instructions.

## Category
Health & Fitness  (Productivity is an acceptable alternative)

## What's new (v1.3.0)
Today's doses with time-grouping and take-all, an adherence streak, a medicine list with per-med detail, a glance, and up to 18 medications added from the Garmin Connect app — each in its own collapsible section with day and hourly time pickers.

## Permissions
- **Background** — reserved for upcoming dose reminders. (No location, no internet, no health data is accessed.)

## Store assets to upload
- App icon: `assets/store_icon.png` (square).
- Screenshots: `assets/today.png`, `assets/medicines.png`, `assets/med_detail.png`, `assets/glance.png`.

---

## ✅ Pre-publish checklist
- [x] **App id set** in `manifest.xml` (`d1662e77-…`). Keep it constant once published — never change it after the first release.
- [ ] **`DEBUG_SEED = false`** in `source/DebugSeed.mc` (it is, by default). For a fully clean build you can also delete `DebugSeed.mc` and its call in `MedMinderApp.onStart`.
- [ ] **Developer verification** complete on the portal (required to list apps).
- [ ] Build the package: `./build.ps1 -Export` → `bin/MedMinder.iq`.
- [ ] Test the **medication slots** flow: set name/dose/days/times in Garmin Connect, sync, and confirm they appear on the watch's Today and Medicine list.
- [ ] Confirm the app launches and the medicine list is empty on first run (fresh install).
