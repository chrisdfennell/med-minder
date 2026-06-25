import Toybox.Lang;
import Toybox.WatchUi;

// Input for the Medications list. Scroll with buttons or swipe; BACK or a
// right-swipe returns to Today.
class MedsDelegate extends WatchUi.BehaviorDelegate {
    var view as MedsView;

    function initialize(v as MedsView) {
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

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    // START on the selected med -> open its detail.
    function onSelect() as Boolean {
        openDetail(view.selected);
        return true;
    }

    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        var c = evt.getCoordinates();
        for (var i = 0; i < view.rowHits.size(); i++) {
            var r = view.rowHits[i];
            if (c[1] >= (r["top"] as Number) && c[1] <= (r["bottom"] as Number)) {
                view.selected = r["index"] as Number;
                openDetail(view.selected);
                break;
            }
        }
        return true;
    }

    function openDetail(index as Number) as Void {
        if (index < 0 || index >= view.meds.size()) {
            return;
        }
        var med = view.meds[index];
        WatchUi.pushView(new MedDetailView(med), new MedDetailDelegate(med), WatchUi.SLIDE_LEFT);
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
