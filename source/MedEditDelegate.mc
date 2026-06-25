import Toybox.Lang;
import Toybox.WatchUi;

// On-watch editor for one med's SCHEDULE. Name and dose come from phone
// settings; here the user sets the scheduled times, the active days, and
// whether reminders are on. Reached with START / tap from a med's detail.
function openMedEditor(med as Dictionary) as Void {
    var delegate = new MedEditDelegate(med);
    WatchUi.pushView(delegate.buildMenu(), delegate, WatchUi.SLIDE_LEFT);
}

class MedEditDelegate extends WatchUi.Menu2InputDelegate {
    // The med dict is mutated in place so the detail/list views (which share the
    // reference) reflect edits on return; every change is also persisted.
    var med as Dictionary;
    var timesItem as WatchUi.MenuItem?;
    var daysItem as WatchUi.MenuItem?;

    function initialize(m as Dictionary) {
        Menu2InputDelegate.initialize();
        med = m;
    }

    function buildMenu() as WatchUi.Menu2 {
        var menu = new WatchUi.Menu2({ :title => med["name"] as String });
        timesItem = new WatchUi.MenuItem("Times", timesSub(), "times", null);
        daysItem = new WatchUi.MenuItem("Days", daysLabel(med["days"] as Number), "days", null);
        menu.addItem(timesItem);
        menu.addItem(daysItem);
        menu.addItem(new WatchUi.ToggleMenuItem("Reminders", null, "rem", (med["enabled"] as Boolean), null));
        return menu;
    }

    function timesSub() as String {
        var t = timesLabel(med["times"] as Array);
        return (t.length() > 0) ? t : "None";
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId() as String;
        if (id.equals("times")) {
            showTimesMenu(med, self, false);
        } else if (id.equals("days")) {
            WatchUi.pushView(buildDaysMenu(med), new DaysMenuDelegate(med, self), WatchUi.SLIDE_LEFT);
        } else if (id.equals("rem")) {
            med["enabled"] = (item as WatchUi.ToggleMenuItem).isEnabled();
            persist();
        }
    }

    function persist() as Void {
        MedStore.putSchedule(
            med["id"] as Number,
            med["times"] as Array<Number>,
            med["days"] as Number,
            med["enabled"] as Boolean);
    }

    // Called by the day/time sub-editors after they change the schedule, so the
    // edit menu's sub-labels stay in sync.
    function onScheduleChanged() as Void {
        if (timesItem != null) { timesItem.setSubLabel(timesSub()); }
        if (daysItem != null) { daysItem.setSubLabel(daysLabel(med["days"] as Number)); }
        WatchUi.requestUpdate();
    }
}
