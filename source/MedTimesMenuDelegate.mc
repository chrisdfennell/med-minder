import Toybox.Lang;
import Toybox.WatchUi;

// Manage a med's scheduled times: one row per time (select to remove) plus an
// "Add time" row (hidden once MAX_TIMES is reached). After any change the menu
// is rebuilt in place via switchToView so the list always reflects current
// state without leaving a stale menu on the stack.
function showTimesMenu(med as Dictionary, parent as MedEditDelegate, replace as Boolean) as Void {
    var menu = buildTimesMenu(med);
    var delegate = new MedTimesMenuDelegate(med, parent);
    if (replace) {
        WatchUi.switchToView(menu, delegate, WatchUi.SLIDE_IMMEDIATE);
    } else {
        WatchUi.pushView(menu, delegate, WatchUi.SLIDE_LEFT);
    }
}

function buildTimesMenu(med as Dictionary) as WatchUi.Menu2 {
    var menu = new WatchUi.Menu2({ :title => "Times" });
    var times = med["times"] as Array<Number>;
    for (var i = 0; i < times.size(); i++) {
        menu.addItem(new WatchUi.MenuItem(formatTime(times[i] as Number), "Remove", "t" + i.format("%d"), null));
    }
    if (times.size() < MAX_TIMES) {
        menu.addItem(new WatchUi.MenuItem("Add time", null, "add", null));
    }
    return menu;
}

class MedTimesMenuDelegate extends WatchUi.Menu2InputDelegate {
    var med as Dictionary;
    var parent as MedEditDelegate;

    function initialize(m as Dictionary, p as MedEditDelegate) {
        Menu2InputDelegate.initialize();
        med = m;
        parent = p;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId() as String;
        if (id.equals("add")) {
            WatchUi.pushView(new TimePicker(), new TimePickerDelegate(med, parent), WatchUi.SLIDE_LEFT);
            return;
        }
        // "t<index>" -> remove that time
        var idx = id.substring(1, id.length()).toNumber();
        var times = med["times"] as Array<Number>;
        var out = [] as Array<Number>;
        for (var i = 0; i < times.size(); i++) {
            if (i != idx) {
                out.add(times[i]);
            }
        }
        med["times"] = out;
        parent.persist();
        parent.onScheduleChanged();
        showTimesMenu(med, parent, true);
    }
}
