import Toybox.Attention;
import Toybox.Lang;
import Toybox.WatchUi;

// Input for the diagnostics screen: scroll the log with buttons/swipe, START
// fires a test vibrate/tone (proves the alert hardware works, independent of the
// background path) and refreshes the log, BACK/right-swipe returns to the meds.
class DiagnosticsDelegate extends WatchUi.BehaviorDelegate {
    var view as DiagnosticsView;

    function initialize(v as DiagnosticsView) {
        BehaviorDelegate.initialize();
        view = v;
    }

    function onNextPage() as Boolean {
        view.moveSelection(1);
        return true;
    }

    function onPreviousPage() as Boolean {
        view.moveSelection(-1);
        return true;
    }

    function onSelect() as Boolean {
        testAlert();
        view.rebuild();
        WatchUi.requestUpdate();
        return true;
    }

    // Foreground-only alert, to confirm the watch CAN vibrate/tone at all. This
    // is NOT the reminder path (background can't use Attention) — it just rules
    // the hardware in or out as the suspect.
    function testAlert() as Void {
        if (!(Toybox has :Attention)) {
            return;
        }
        if (Attention has :vibrate) {
            var pattern = [new Attention.VibeProfile(100, 600)] as Array<Attention.VibeProfile>;
            Attention.vibrate(pattern);
        }
        if (Attention has :playTone) {
            Attention.playTone(Attention.TONE_ALERT_HI);
        }
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    function onSwipe(evt as WatchUi.SwipeEvent) as Boolean {
        var dir = evt.getDirection();
        if (dir == WatchUi.SWIPE_UP) {
            view.moveSelection(1);
        } else if (dir == WatchUi.SWIPE_DOWN) {
            view.moveSelection(-1);
        } else if (dir == WatchUi.SWIPE_RIGHT) {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
        return true;
    }
}
