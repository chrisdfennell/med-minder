import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// The medicine list: a clean reference catalog of every med — name, dose,
// frequency (e.g. "3x a day"), and scheduled times. Read-only for now;
// reachable from Today via MENU or a left swipe.
class MedsView extends WatchUi.View {
    var meds as Array<Dictionary> = [] as Array<Dictionary>;
    var selected as Number = 0;
    var firstVisible as Number = 0;
    var rowHits as Array<Dictionary> = [] as Array<Dictionary>;

    private const CARD_H = 62;
    private const VISIBLE = 3;
    private const ACCENT = 0x5AC8FA;

    function initialize() {
        View.initialize();
    }

    function onShow() as Void {
        rebuild();
    }

    function rebuild() as Void {
        meds = MedStore.loadMeds();
        if (selected >= meds.size()) {
            selected = meds.size() - 1;
        }
        if (selected < 0) {
            selected = 0;
        }
    }

    function moveSelection(delta as Number) as Void {
        var n = meds.size();
        if (n == 0) {
            return;
        }
        selected = (selected + delta + n) % n;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        rowHits = [] as Array<Dictionary>;
        dc.setColor(Graphics.COLOR_WHITE, 0x000000);
        dc.clear();

        // Header
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.105, Graphics.FONT_TINY, "Medications",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(0x888E98, Graphics.COLOR_TRANSPARENT);
        var countText = meds.size().format("%d") + (meds.size() == 1 ? " medication" : " medications");
        dc.drawText(w / 2, h * 0.185, Graphics.FONT_XTINY, countText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        if (meds.size() == 0) {
            dc.setColor(0xAAAAAA, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, h * 0.44, Graphics.FONT_SMALL, "No medications yet",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.setColor(0x7C828C, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, h * 0.56, Graphics.FONT_XTINY, "Add names in phone settings,",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.drawText(w / 2, h * 0.63, Graphics.FONT_XTINY, "then set times here",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        if (selected < firstVisible) {
            firstVisible = selected;
        }
        if (selected >= firstVisible + VISIBLE) {
            firstVisible = selected - VISIBLE + 1;
        }

        var listTop = (h * 0.24).toNumber();
        for (var i = 0; i < meds.size(); i++) {
            if (i < firstVisible || i >= firstVisible + VISIBLE) {
                continue;
            }
            drawCard(dc, w, meds[i], i, listTop + (i - firstVisible) * CARD_H);
        }

        drawScrollbar(dc, w, listTop);
    }

    function drawCard(dc as Dc, w as Number, med as Dictionary, index as Number, y as Number) as Void {
        rowHits.add({ "index" => index, "top" => y, "bottom" => y + CARD_H });

        var pad = 18;
        if (index == selected) {
            dc.setColor(0x1A2129, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(pad - 6, y + 3, w - 2 * (pad - 6), CARD_H - 6, 8);
        }

        // Accent bar
        dc.setColor(ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(pad, y + 12, 4, CARD_H - 24, 2);

        var textX = pad + 14;
        // Name
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(textX, y + 9, Graphics.FONT_SMALL, med["name"] as String, Graphics.TEXT_JUSTIFY_LEFT);

        // dose · frequency
        var dose = (med["dose"] == null) ? "" : (med["dose"] as String);
        var freq = MedStore.freqOf(med);
        var sub = dose;
        if (freq.length() > 0) {
            sub = (sub.length() > 0) ? (sub + "   " + freq) : freq;
        }
        dc.setColor(0xA9AFB9, Graphics.COLOR_TRANSPARENT);
        dc.drawText(textX, y + 33, Graphics.FONT_XTINY, sub, Graphics.TEXT_JUSTIFY_LEFT);

        // times (dimmer)
        var times = timesLabel(med["times"] as Array);
        if (times.length() > 0) {
            dc.setColor(0x636A75, Graphics.COLOR_TRANSPARENT);
            dc.drawText(textX, y + 49, Graphics.FONT_XTINY, times, Graphics.TEXT_JUSTIFY_LEFT);
        }
    }

    function drawScrollbar(dc as Dc, w as Number, listTop as Number) as Void {
        if (meds.size() <= VISIBLE) {
            return;
        }
        var trackH = VISIBLE * CARD_H;
        var x = w - 7;
        dc.setColor(0x2A2F37, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(x, listTop, 3, trackH, 1);
        var thumbH = (trackH * VISIBLE) / meds.size();
        if (thumbH < 12) { thumbH = 12; }
        var maxScroll = meds.size() - VISIBLE;
        var thumbY = listTop + ((trackH - thumbH) * firstVisible) / maxScroll;
        dc.setColor(0x6B7280, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(x, thumbY, 3, thumbH, 1);
    }
}
