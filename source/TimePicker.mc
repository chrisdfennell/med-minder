import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// A column of evenly-spaced numbers for a Picker. (Connect IQ has no built-in
// number factory; the SDK samples each ship their own — this is that.)
class NumberFactory extends WatchUi.PickerFactory {
    private var mStart as Number;
    private var mStop as Number;
    private var mIncrement as Number;
    private var mFormat as String;

    function initialize(start as Number, stop as Number, increment as Number, format as String) {
        PickerFactory.initialize();
        mStart = start;
        mStop = stop;
        mIncrement = increment;
        mFormat = format;
    }

    function getSize() as Number {
        return (mStop - mStart) / mIncrement + 1;
    }

    function getValue(index as Number) as Object? {
        return mStart + index * mIncrement;
    }

    function getDrawable(index as Number, isSelected as Boolean) as WatchUi.Drawable? {
        return new WatchUi.Text({
            :text => (mStart + index * mIncrement).format(mFormat),
            :color => Graphics.COLOR_WHITE,
            :font => Graphics.FONT_NUMBER_MILD,
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => WatchUi.LAYOUT_VALIGN_CENTER
        });
    }
}

// Two-wheel hour:minute picker used to add a scheduled time. Hours are 0-23 and
// minutes step by 5; the accepted value is converted to minutes-after-midnight,
// matching how times are stored everywhere else.
class TimePicker extends WatchUi.Picker {
    function initialize() {
        var title = new WatchUi.Text({
            :text => "Add time",
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => WatchUi.LAYOUT_VALIGN_BOTTOM,
            :color => Graphics.COLOR_WHITE
        });
        var hours = new NumberFactory(0, 23, 1, "%d");
        var colon = new WatchUi.Text({ :text => ":", :color => Graphics.COLOR_WHITE, :font => Graphics.FONT_NUMBER_MILD });
        var minutes = new NumberFactory(0, 55, 5, "%02d");
        Picker.initialize({
            :title => title,
            :pattern => [hours, colon, minutes] as Array,
            :defaults => [8, 0, 0] as Array<Number>
        });
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        Picker.onUpdate(dc);
    }
}

class TimePickerDelegate extends WatchUi.PickerDelegate {
    var med as Dictionary;
    var parent as MedEditDelegate;

    function initialize(m as Dictionary, p as MedEditDelegate) {
        PickerDelegate.initialize();
        med = m;
        parent = p;
    }

    function onCancel() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    // values[1] is the static ":" column; the wheels are values[0] and [2].
    function onAccept(values as Array) as Boolean {
        var mins = (values[0] as Number) * 60 + (values[2] as Number);
        var times = med["times"] as Array<Number>;
        if (!contains(times, mins)) {
            times.add(mins);
            for (var a = 1; a < times.size(); a++) {
                var key = times[a];
                var b = a - 1;
                while (b >= 0 && times[b] > key) {
                    times[b + 1] = times[b];
                    b--;
                }
                times[b + 1] = key;
            }
            med["times"] = times;
            parent.persist();
            parent.onScheduleChanged();
        }
        // Replace the picker with the refreshed times list (no stale menu).
        showTimesMenu(med, parent, true);
        return true;
    }
}
