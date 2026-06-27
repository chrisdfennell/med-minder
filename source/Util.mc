import Toybox.Lang;
import Toybox.System;
import Toybox.Time;

// Small string/time helpers kept free of any Toybox String API that varies
// across SDK versions (no split/trim/toLower assumptions) so the parsing is
// predictable on every device.

function isSpace(ch as String) as Boolean {
    return ch.equals(" ") || ch.equals("\t");
}

function strTrim(s) as String {
    if (s == null) {
        return "";
    }
    var a = 0;
    var b = s.length();
    while (a < b && isSpace(s.substring(a, a + 1))) {
        a++;
    }
    while (b > a && isSpace(s.substring(b - 1, b))) {
        b--;
    }
    return s.substring(a, b);
}

// ASCII lower-case for case-insensitive name matching between phone and watch.
function strLower(s as String) as String {
    var out = "";
    for (var i = 0; i < s.length(); i++) {
        var ch = s.substring(i, i + 1);
        var c = ch.toCharArray()[0] as Char;
        var code = c.toNumber();
        if (code >= 65 && code <= 90) {
            out += (code + 32).toChar().toString();
        } else {
            out += ch;
        }
    }
    return out;
}

// Parse "HH:MM" -> minutes after midnight, or null if malformed.
function parseHHMM(tokenIn as String) {
    var tok = strTrim(tokenIn);
    if (tok.length() < 3) {
        return null;
    }
    var colon = -1;
    for (var i = 0; i < tok.length(); i++) {
        if (tok.substring(i, i + 1).equals(":")) {
            colon = i;
            break;
        }
    }
    if (colon <= 0 || colon >= tok.length() - 1) {
        return null;
    }
    var h = tok.substring(0, colon).toNumber();
    var m = tok.substring(colon + 1, tok.length()).toNumber();
    if (h == null || m == null) {
        return null;
    }
    if (h < 0 || h > 23 || m < 0 || m > 59) {
        return null;
    }
    return h * 60 + m;
}

// Split a string on a single-character delimiter. (Toybox.Lang.String has no
// split, so this is the shared primitive used by the time/list parsers.)
function splitStr(s, delim as String) as Array {
    var out = [] as Array;
    if (s == null) {
        return out;
    }
    var token = "";
    for (var i = 0; i < s.length(); i++) {
        var ch = s.substring(i, i + 1);
        if (ch.equals(delim)) {
            out.add(token);
            token = "";
        } else {
            token += ch;
        }
    }
    out.add(token);
    return out;
}

// Parse a list like "09:00,21:00" or "09:00 21:00" -> sorted Array of minutes.
// Both comma and space are accepted as separators.
function parseTimes(s) as Array {
    var result = [] as Array;
    if (s == null) {
        return result;
    }
    var token = "";
    for (var i = 0; i <= s.length(); i++) {
        var ch = (i < s.length()) ? s.substring(i, i + 1) : ",";
        if (ch.equals(",") || ch.equals(" ")) {
            var m = parseHHMM(token);
            if (m != null && !contains(result, m)) {
                result.add(m);
            }
            token = "";
        } else {
            token += ch;
        }
    }
    // insertion sort ascending
    for (var a = 1; a < result.size(); a++) {
        var key = result[a];
        var b = a - 1;
        while (b >= 0 && result[b] > key) {
            result[b + 1] = result[b];
            b--;
        }
        result[b + 1] = key;
    }
    return result;
}

function contains(arr as Array, v) as Boolean {
    for (var i = 0; i < arr.size(); i++) {
        if (arr[i] == v) {
            return true;
        }
    }
    return false;
}

// minutes-after-midnight -> display string, honoring the device 12/24h setting.
function formatTime(minutes as Number) as String {
    var h = minutes / 60;
    var m = minutes % 60;
    if (System.getDeviceSettings().is24Hour) {
        return h.format("%02d") + ":" + m.format("%02d");
    }
    var ap = (h < 12) ? "AM" : "PM";
    var hh = h % 12;
    if (hh == 0) {
        hh = 12;
    }
    return hh.format("%d") + ":" + m.format("%02d") + " " + ap;
}

// Compact "12s" / "5m" / "1h3m" / "2d" elapsed since a past epoch ("never" if
// 0/future-clamped). Used by the diagnostics screen for "last bg run" etc.
function agoLabel(epoch as Number) as String {
    if (epoch <= 0) {
        return "never";
    }
    var s = Time.now().value() - epoch;
    if (s < 0) {
        s = 0;
    }
    if (s < 60) {
        return s.format("%d") + "s";
    }
    var m = s / 60;
    if (m < 60) {
        return m.format("%d") + "m";
    }
    var hh = m / 60;
    if (hh < 24) {
        return hh.format("%d") + "h" + (m % 60).format("%d") + "m";
    }
    return (hh / 24).format("%d") + "d";
}

// "Every day", or a short list like "Mon, Wed, Fri" from a day bitmask.
function daysLabel(mask as Number) as String {
    if (mask == ALL_DAYS) {
        return "Every day";
    }
    var names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    var s = "";
    for (var i = 0; i < 7; i++) {
        if ((mask & (1 << i)) != 0) {
            if (s.length() > 0) {
                s += ", ";
            }
            s += names[i];
        }
    }
    return (s.length() > 0) ? s : "No days";
}

// "8:00 AM  ·  2:00 PM  ·  8:00 PM" for a med's scheduled times ("" if none).
function timesLabel(times as Array) as String {
    if (times == null || times.size() == 0) {
        return "";
    }
    var s = "";
    for (var i = 0; i < times.size(); i++) {
        if (i > 0) {
            s += "   ";
        }
        s += formatTime(times[i] as Number);
    }
    return s;
}
