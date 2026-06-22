import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Full detail for one med: name, dose, frequency, scheduled times, and which
// days it's taken. Reached by tapping (or START on) a row in the medicine list.
class MedDetailView extends WatchUi.View {
    var med as Dictionary;

    function initialize(m as Dictionary) {
        View.initialize();
        med = m;
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Graphics.COLOR_WHITE, 0x000000);
        dc.clear();

        // Name
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.15, Graphics.FONT_MEDIUM, med["name"] as String,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Accent underline
        dc.setColor(0x5AC8FA, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(w / 2 - 22, (h * 0.235).toNumber(), 44, 3, 1);

        // Build the field list (only what's present)
        var fields = [] as Array;
        var dose = (med["dose"] == null) ? "" : (med["dose"] as String);
        if (dose.length() > 0) {
            fields.add(["Dose", dose]);
        }
        fields.add(["Frequency", MedStore.freqOf(med)]);
        var times = med["times"] as Array;
        if (times != null && times.size() > 0) {
            fields.add(["Times", timesLabel(times)]);
            fields.add(["Schedule", daysLabel(med["days"] as Number)]);
        }
        if ((med["enabled"] as Boolean) == false) {
            fields.add(["Reminders", "Off"]);
        }

        // Lay the fields out evenly in the lower portion of the screen.
        var top = h * 0.30;
        var bottom = h * 0.92;
        var slot = (bottom - top) / fields.size();
        for (var i = 0; i < fields.size(); i++) {
            var pair = fields[i] as Array;
            var cy = top + slot * i + slot / 2;
            dc.setColor(0x7C828C, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, cy - 12, Graphics.FONT_XTINY, pair[0] as String,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, cy + 10, Graphics.FONT_XTINY, pair[1] as String,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
}
