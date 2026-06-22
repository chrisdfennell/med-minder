import Toybox.Lang;
import Toybox.WatchUi;

// Input for the Today screen. BehaviorDelegate gives us button behaviors
// (UP/DOWN/START/MENU) for free; we add onTap/onSwipe so touch devices
// (Venu, Vivoactive, touch Forerunners) get swipe-to-scroll and tap-to-take.
class TodayDelegate extends WatchUi.BehaviorDelegate {
    var view as TodayView;

    function initialize(v as TodayView) {
        BehaviorDelegate.initialize();
        view = v;
    }

    // --- buttons ---
    function onNextPage() as Boolean {
        view.moveSelection(1);
        return true;
    }

    function onPreviousPage() as Boolean {
        view.moveSelection(-1);
        return true;
    }

    function onSelect() as Boolean {
        view.primaryAct();
        return true;
    }

    // MENU opens the medicine list (reference catalog).
    function onMenu() as Boolean {
        openMeds();
        return true;
    }

    function openMeds() as Void {
        var v = new MedsView();
        WatchUi.pushView(v, new MedsDelegate(v), WatchUi.SLIDE_LEFT);
    }

    // --- touch ---
    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        var c = evt.getCoordinates();
        view.handleTap(c[0], c[1]);
        return true;
    }

    function onSwipe(evt as WatchUi.SwipeEvent) as Boolean {
        var dir = evt.getDirection();
        if (dir == WatchUi.SWIPE_UP) {
            view.moveSelection(1);   // swipe up -> reveal lower rows
        } else if (dir == WatchUi.SWIPE_DOWN) {
            view.moveSelection(-1);
        } else if (dir == WatchUi.SWIPE_LEFT) {
            openMeds();              // swipe left -> medicine list
        }
        return true;
    }
}
