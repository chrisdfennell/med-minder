import Toybox.Application;
import Toybox.Background;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

class MedMinderApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary or Null) as Void {
        // Pull any meds defined on the phone into the watch-owned list, then
        // trim old adherence history.
        MedStore.importFromSettings();
        DebugSeed.run();
        MedStore.pruneLog();
        // Make sure the reminder background service is scheduled. Runs on every
        // launch (and in the background process) so reminders stay active.
        rescheduleReminders();
    }

    // Fires when the user saves med slots in the Garmin Connect app.
    function onSettingsChanged() as Void {
        MedStore.importFromSettings();
        rescheduleReminders();
        WatchUi.requestUpdate();
    }

    // The background entry point. Its mere presence tells the system this app
    // has a background service; the system calls it (not getInitialView) when a
    // temporal event fires while the app is closed.
    function getServiceDelegate() as [System.ServiceDelegate] {
        return [new ReminderService()];
    }

    function onStop(state as Dictionary or Null) as Void {
    }

    function getInitialView() {
        var view = new TodayView();
        return [ view, new TodayDelegate(view) ];
    }

    function getGlanceView() {
        return [ new MedGlanceView() ];
    }
}

function getApp() as MedMinderApp {
    return Application.getApp() as MedMinderApp;
}

// (Re)register the periodic reminder check. We always register at the platform
// minimum (5 min) rather than gating on whether meds exist, so reminders work
// the instant a user adds a med on the watch without needing to relaunch the
// app. The service reads the live schedule from storage on each tick, so an
// empty schedule simply means no wake is requested. Reminders are therefore
// accurate to within about 5 minutes, the finest granularity the platform
// allows for background events.
function rescheduleReminders() as Void {
    if (!(Toybox has :Background)) {
        return;
    }
    Background.registerForTemporalEvent(new Time.Duration(5 * 60));
}
