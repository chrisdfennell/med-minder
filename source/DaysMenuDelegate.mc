import Toybox.Lang;
import Toybox.WatchUi;

// Pick the days a med is taken: a checkbox per weekday, initialized from the
// med's day bitmask (bit0=Sun .. bit6=Sat). Toggling persists immediately so
// the choice survives even if the user just swipes away.
function buildDaysMenu(med as Dictionary) as WatchUi.CheckboxMenu {
    var menu = new WatchUi.CheckboxMenu({ :title => "Days" });
    var names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    var mask = med["days"] as Number;
    for (var i = 0; i < 7; i++) {
        var on = (mask & (1 << i)) != 0;
        menu.addItem(new WatchUi.CheckboxMenuItem(names[i], null, i, on, null));
    }
    return menu;
}

class DaysMenuDelegate extends WatchUi.Menu2InputDelegate {
    var med as Dictionary;
    var parent as MedEditDelegate;

    function initialize(m as Dictionary, p as MedEditDelegate) {
        Menu2InputDelegate.initialize();
        med = m;
        parent = p;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var cb = item as WatchUi.CheckboxMenuItem;
        var bit = 1 << (item.getId() as Number);
        var mask = med["days"] as Number;
        if (cb.isChecked()) {
            mask |= bit;
        } else {
            mask = mask & (~bit);
        }
        med["days"] = mask;
        parent.persist();
        parent.onScheduleChanged();
    }
}
