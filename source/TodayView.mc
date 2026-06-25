import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// The home screen: today's doses grouped by time, with a "Take all today" action
// and per-time "All (N)" group headers. Works with buttons (UP/DOWN + START/MENU)
// and touch (swipe to scroll, tap a row to take it).
class TodayView extends WatchUi.View {
    var items as Array<Dictionary> = [] as Array<Dictionary>;
    var selected as Number = 0;
    var firstVisible as Number = 0;
    // Hit-test rectangles for the rows drawn in the last onUpdate (touch support).
    var rowHits as Array<Dictionary> = [] as Array<Dictionary>;

    private const ROW_H = 38;
    private const VISIBLE = 4;

    function initialize() {
        View.initialize();
    }

    function onShow() as Void {
        rebuild();
    }

    function rebuild() as Void {
        items = MedStore.todayItems();
        if (selected >= items.size()) {
            selected = items.size() - 1;
        }
        if (selected < 0) {
            selected = 0;
        }
    }

    function moveSelection(delta as Number) as Void {
        var n = items.size();
        if (n == 0) {
            return;
        }
        selected = (selected + delta + n) % n;
        WatchUi.requestUpdate();
    }

    // START / tap: take (or take-all for group/takeall items).
    function primaryAct() as Void {
        actOn(selected, STATUS_TAKEN);
    }

    // MENU / long action: skip.
    function secondaryAct() as Void {
        actOn(selected, STATUS_SKIPPED);
    }

    function actOn(index as Number, targetStatus as Number) as Void {
        if (index < 0 || index >= items.size()) {
            return;
        }
        var item = items[index];
        var doses = item["doses"] as Array<Dictionary>;
        // Toggle: if it's already entirely at the target, clear back to pending.
        var newStatus = ((item["status"] as Number) == targetStatus) ? STATUS_PENDING : targetStatus;
        MedStore.setStatusForDoses(doses, newStatus);
        rebuild();
        WatchUi.requestUpdate();
    }

    // Touch: find the row under (x,y); select and take it.
    function handleTap(x as Number, y as Number) as Void {
        for (var i = 0; i < rowHits.size(); i++) {
            var r = rowHits[i];
            if (y >= (r["top"] as Number) && y <= (r["bottom"] as Number)) {
                selected = r["index"] as Number;
                primaryAct();
                return;
            }
        }
    }

    function statusColor(status as Number) as Number {
        if (status == STATUS_TAKEN) {
            return 0x57C788;
        } else if (status == STATUS_SKIPPED) {
            return 0xFFB02E;
        } else if (status == STATUS_PARTIAL) {
            return 0x4FA3FF;
        } else if (status == STATUS_MISSED) {
            return 0xDA3741;
        }
        return 0x666C76; // pending
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        rowHits = [] as Array<Dictionary>;
        dc.setColor(Graphics.COLOR_WHITE, 0x000000);
        dc.clear();

        // Header
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.13, Graphics.FONT_TINY, "Today",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var streak = MedStore.computeStreak();
        var streakText = (streak > 0) ? (streak.format("%d") + "-day streak") : "Build your streak";
        dc.setColor((streak > 0) ? 0x57C788 : 0x888E98, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.22, Graphics.FONT_XTINY, streakText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        if (items.size() == 0) {
            // Meds can exist with no doses due today — either none are scheduled
            // yet (set times on the watch) or today isn't one of their days.
            var hasMeds = MedStore.loadMeds().size() > 0;
            dc.setColor(0xAAAAAA, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, h / 2, Graphics.FONT_SMALL, hasMeds ? "Nothing due today" : "No meds yet",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.setColor(0x666C76, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, h / 2 + 26, Graphics.FONT_XTINY,
                hasMeds ? "Set times in Medications" : "Add names in phone settings",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        // Keep the selected row inside the visible window
        if (selected < firstVisible) {
            firstVisible = selected;
        }
        if (selected >= firstVisible + VISIBLE) {
            firstVisible = selected - VISIBLE + 1;
        }

        var listTop = (h * 0.30).toNumber();
        for (var i = 0; i < items.size(); i++) {
            if (i < firstVisible || i >= firstVisible + VISIBLE) {
                continue;
            }
            drawRow(dc, w, items[i], i, listTop + (i - firstVisible) * ROW_H);
        }

        drawScrollbar(dc, w, h, listTop);

        // Hint footer
        dc.setColor(0x555B64, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h - (h * 0.10), Graphics.FONT_XTINY, "START take   MENU list",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function drawRow(dc as Dc, w as Number, item as Dictionary, index as Number, y as Number) as Void {
        var kind = item["kind"] as String;
        var status = item["status"] as Number;
        var indent = item["indent"] as Boolean;
        var cy = y + ROW_H / 2;

        rowHits.add({ "index" => index, "top" => y, "bottom" => y + ROW_H });

        if (index == selected) {
            dc.setColor(0x1E2630, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(12, y + 2, w - 24, ROW_H - 4, 6);
        }

        var dotX = indent ? 48 : 30;
        var textX = indent ? 64 : 50;

        if (kind.equals("takeall")) {
            // Distinct double-check glyph for the whole-day action.
            dc.setColor(statusColor(status), Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(24, cy - 7, 14, 14, 3);
            dc.setColor(0xCFD3DA, Graphics.COLOR_TRANSPARENT);
            dc.drawText(textX, cy, Graphics.FONT_XTINY, item["label"] as String,
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        dc.setColor(statusColor(status), Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(dotX, cy, 6);

        var textColor;
        if (status == STATUS_TAKEN) {
            textColor = 0x57C788;
        } else if (status == STATUS_SKIPPED) {
            textColor = 0xB7891F;
        } else if (kind.equals("group")) {
            textColor = 0xCFD3DA;
        } else {
            textColor = Graphics.COLOR_WHITE;
        }
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(textX, cy, Graphics.FONT_XTINY, item["label"] as String,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function drawScrollbar(dc as Dc, w as Number, h as Number, listTop as Number) as Void {
        if (items.size() <= VISIBLE) {
            return;
        }
        var trackTop = listTop;
        var trackH = VISIBLE * ROW_H;
        var x = w - 7;
        dc.setColor(0x2A2F37, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(x, trackTop, 3, trackH, 1);
        var thumbH = (trackH * VISIBLE) / items.size();
        if (thumbH < 12) { thumbH = 12; }
        var maxScroll = items.size() - VISIBLE;
        var thumbY = trackTop + ((trackH - thumbH) * firstVisible) / maxScroll;
        dc.setColor(0x6B7280, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(x, thumbY, 3, thumbH, 1);
    }
}
