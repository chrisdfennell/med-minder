import Toybox.Application;
import Toybox.Lang;
import Toybox.System;
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
    }

    // Fires when the user saves med slots in the Garmin Connect app.
    function onSettingsChanged() as Void {
        MedStore.importFromSettings();
        WatchUi.requestUpdate();
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
