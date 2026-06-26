import Toybox.Background;
import Toybox.Lang;
import Toybox.System;

// Background service that drives the actual reminders. It runs on a periodic
// temporal event (every 5 minutes — the platform minimum) while the app is
// closed. When a scheduled dose has just come due, it asks the system to wake
// the app, which is the ONLY sanctioned way to alert the user from a background
// process: it shows a prompt and vibrates/tones on devices that support it.
// Toybox.Attention (direct vibrate/tone) is not available in a background
// process, so requestApplicationWake is the mechanism, not a fallback.
//
// The service self-heals: because it re-checks every interval against a stored
// high-water mark, a missed tick (watch off, BLE drop) is caught on the next
// one rather than silently dropping a dose — the right trade for a med app.
(:background)
class ReminderService extends System.ServiceDelegate {

    function initialize() {
        ServiceDelegate.initialize();
    }

    function onTemporalEvent() as Void {
        var due = MedStore.dueReminders();
        // Advance the high-water mark first so each dose alerts exactly once,
        // whether or not we end up waking the app this tick.
        MedStore.markReminderCheck();
        if (due.size() > 0) {
            // Terminal action of the background run — requestApplicationWake is
            // the last call (we do not also Background.exit, which could race
            // the wake request on some devices).
            Background.requestApplicationWake(MedStore.reminderMessage(due));
            return;
        }
        Background.exit(null);
    }
}
