import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// One-swipe-away ambient surface: the next dose due today + the current streak.
class MedGlanceView extends WatchUi.GlanceView {

    function initialize() {
        GlanceView.initialize();
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(0x0B0D12, 0x0B0D12);
        dc.clear();

        // The system draws the app icon on the left; keep clear of that zone.
        var left = 50;
        var next = MedStore.nextDose();
        var streak = MedStore.computeStreak();

        var title;
        var titleColor;
        if (next != null) {
            title = formatTime(next["minutes"] as Number) + "  " + (next["name"] as String);
            titleColor = Graphics.COLOR_WHITE;
        } else {
            title = "Nothing due";
            titleColor = 0x9AA0AA;
        }

        var bh = dc.getFontHeight(Graphics.FONT_TINY);
        var sh = dc.getFontHeight(Graphics.FONT_XTINY);
        var blockH = bh + 2 + sh;
        var y = (h - blockH) / 2;
        if (y < 0) {
            y = 0;
        }

        dc.setColor(titleColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(left, y, Graphics.FONT_TINY, title, Graphics.TEXT_JUSTIFY_LEFT);

        var sub = (streak > 0) ? (streak.format("%d") + "-day streak") : "MedMinder";
        dc.setColor((streak > 0) ? 0x57C788 : 0x888E98, Graphics.COLOR_TRANSPARENT);
        dc.drawText(left, y + bh + 2, Graphics.FONT_XTINY, sub, Graphics.TEXT_JUSTIFY_LEFT);
    }
}
