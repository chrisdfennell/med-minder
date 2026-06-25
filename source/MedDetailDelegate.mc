import Toybox.Lang;
import Toybox.WatchUi;

// START or a tap opens the on-watch schedule editor for this med. BACK or a
// right-swipe returns to the medicine list.
class MedDetailDelegate extends WatchUi.BehaviorDelegate {
    var med as Dictionary;

    function initialize(m as Dictionary) {
        BehaviorDelegate.initialize();
        med = m;
    }

    function onSelect() as Boolean {
        openMedEditor(med);
        return true;
    }

    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        openMedEditor(med);
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    function onSwipe(evt as WatchUi.SwipeEvent) as Boolean {
        if (evt.getDirection() == WatchUi.SWIPE_RIGHT) {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
        return true;
    }
}
