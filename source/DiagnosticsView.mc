import Toybox.Attention;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Time;

// On-watch diagnostics for the reminder background service, reachable from the
// Medications list via MENU. With no debugger on real hardware, this is how we
// answer "are reminders even running?": the background service appends to
// MedStore's bg log on every run, and this screen reads it back, alongside the
// current schedule the background sees and whether the wake API exists on this
// device. Temporary debugging aid — remove once reminders are confirmed.
class DiagnosticsView extends WatchUi.View {
    var lines as Array<String> = [] as Array<String>;
    var top as Number = 0;
    private const VISIBLE = 9;

    function initialize() {
        View.initialize();
    }

    function onShow() as Void {
        rebuild();
    }

    function rebuild() as Void {
        var out = [] as Array<String>;
        var wake = (Toybox has :Background) && (Background has :requestApplicationWake);
        out.add("Wake API: " + (wake ? "yes" : "NO"));
        var vib = (Toybox has :Attention) && (Attention has :vibrate);
        out.add("Vibrate API: " + (vib ? "yes" : "NO"));
        out.add("(START = test vibrate)");

        var log = MedStore.bgLog();
        var lastRun = (log.size() > 0) ? (log[log.size() - 1]["t"] as Number) : 0;
        out.add("Last bg run: " + agoLabel(lastRun));
        out.add("Last check: " + agoLabel(MedStore.lastNotify()));

        var doses = MedStore.todayDoses();
        out.add("Meds: " + MedStore.loadMeds().size().format("%d")
            + "  Doses today: " + doses.size().format("%d"));

        var next = MedStore.nextDose();
        if (next != null) {
            out.add("Next: " + formatTime(next["minutes"] as Number) + " " + (next["name"] as String));
        } else {
            out.add("Next: none pending");
        }

        out.add("--- bg log (newest) ---");
        if (log.size() == 0) {
            out.add("(empty - bg never ran)");
        } else {
            for (var i = log.size() - 1; i >= 0; i--) {
                out.add(agoLabel(log[i]["t"] as Number) + "  " + (log[i]["msg"] as String));
            }
        }
        lines = out;
        top = 0;
    }

    function moveSelection(delta as Number) as Void {
        top += delta;
        var max = lines.size() - VISIBLE;
        if (max < 0) { max = 0; }
        if (top > max) { top = max; }
        if (top < 0) { top = 0; }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Graphics.COLOR_WHITE, 0x000000);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.07, Graphics.FONT_XTINY, "Diagnostics",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var y = (h * 0.16).toNumber();
        var lineH = (h * 0.088).toNumber();
        for (var i = top; i < lines.size() && i < top + VISIBLE; i++) {
            var s = lines[i];
            var col = 0xC8CDD4;
            if (s.find("ERR") != null || s.find("NO") != null) {
                col = 0xFF5A5A;       // problem
            } else if (s.find("WAKE") != null) {
                col = 0x5AC8FA;       // a reminder actually fired
            }
            dc.setColor(col, Graphics.COLOR_TRANSPARENT);
            dc.drawText((w * 0.07).toNumber(), y, Graphics.FONT_XTINY, s, Graphics.TEXT_JUSTIFY_LEFT);
            y += lineH;
        }

        // Scroll hint when there is more below the fold.
        if (top + VISIBLE < lines.size()) {
            dc.setColor(0x636A75, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, h * 0.95, Graphics.FONT_XTINY, "more ▼",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
}
