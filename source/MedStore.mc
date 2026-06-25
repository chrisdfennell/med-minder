import Toybox.Application;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

// ---- Storage keys & constants -------------------------------------------------
const KEY_MEDS = "meds";
const KEY_LOG = "log";

const STATUS_PENDING = 0;
const STATUS_TAKEN = 1;
const STATUS_SKIPPED = 2;
const STATUS_MISSED = 3; // set by the background service in milestone M2
const STATUS_PARTIAL = 4; // display-only: a group with a mix of statuses

const ALL_DAYS = 0x7F; // bit0=Sun .. bit6=Sat
const LOG_RETENTION_DAYS = 90;

// Number of fixed medication slots exposed in phone settings. Must match the
// cfgM<n>Name / cfgM<n>Dose properties generated in resources/settings/. Bump
// this and regenerate the settings/properties XML to offer more slots.
const SLOT_COUNT = 18;

// Max scheduled times a med may have, enforced by the on-watch editor. Phone
// settings no longer carry times, so this is a UI cap only (not a sync limit).
const MAX_TIMES = 6;

// MedStore owns all persistence. The data model is HYBRID: phone settings carry
// only each med's Name and Dose (kept tiny so all slots save in one sync, well
// under Garmin's 8 KB properties cap). The SCHEDULE — times, active days, and
// whether reminders are on — is owned and edited on the watch.
//
// importFromSettings() MERGES on every launch and settings sync: it refreshes
// name/dose from the phone slots while preserving the watch-owned schedule. The
// adherence log is keyed by med id (= slot number), stable as long as a med
// keeps its slot.
//
// Values come back from Storage as a poly ValueType, so reads are cast at the
// point of use (Number/String/Boolean/Array) to satisfy strict type checking.
//
// med  = { "id", "name", "dose", "times" (Array<Number> min), "days" (mask), "enabled" }
// log entry = { "m" (medId), "d" (due epoch), "s" (status), "a" (acted epoch) }
class MedStore {

    // ---- meds ----
    static function loadMeds() as Array<Dictionary> {
        var meds = Application.Storage.getValue(KEY_MEDS);
        return (meds == null) ? ([] as Array<Dictionary>) : (meds as Array<Dictionary>);
    }

    static function saveMeds(meds as Array<Dictionary>) as Void {
        Application.Storage.setValue(KEY_MEDS, meds);
    }

    static function nextId(meds as Array<Dictionary>) as Number {
        var max = 0;
        for (var i = 0; i < meds.size(); i++) {
            var id = meds[i]["id"] as Number;
            if (id > max) {
                max = id;
            }
        }
        return max + 1;
    }

    // Create or update a med matched case-insensitively by name. Returns the id.
    static function upsert(name as String, dose as String, freq as String, times as Array<Number>, days as Number, enabled as Boolean) as Number {
        var meds = loadMeds();
        var key = strLower(strTrim(name));
        if (key.length() == 0) {
            return -1;
        }
        var d = (dose == null) ? "" : strTrim(dose);
        var f = (freq == null) ? "" : strTrim(freq);
        for (var i = 0; i < meds.size(); i++) {
            if (strLower(strTrim(meds[i]["name"] as String)).equals(key)) {
                meds[i]["dose"] = d;
                meds[i]["freq"] = f;
                meds[i]["times"] = times;
                meds[i]["days"] = days;
                meds[i]["enabled"] = enabled;
                saveMeds(meds);
                return meds[i]["id"] as Number;
            }
        }
        var id = nextId(meds);
        meds.add({
            "id" => id,
            "name" => strTrim(name),
            "dose" => d,
            "freq" => f,
            "times" => times,
            "days" => days,
            "enabled" => enabled
        });
        saveMeds(meds);
        return id;
    }

    // A med's frequency for display: the entered text if any, else derived from
    // the scheduled time count. "As needed" when there are no times.
    static function freqOf(med as Dictionary) as String {
        var f = med["freq"];
        if (f != null && strTrim(f as String).length() > 0) {
            return strTrim(f as String);
        }
        var times = med["times"] as Array<Number>;
        var n = (times == null) ? 0 : times.size();
        if (n == 0) {
            return "As needed";
        }
        var label = (n == 1) ? "Once daily" : (n.format("%d") + "x daily");
        if ((med["days"] as Number) != ALL_DAYS) {
            label = (n == 1) ? "Once, select days" : (n.format("%d") + "x, select days");
        }
        return label;
    }

    // Persist the on-watch schedule for one med (matched by id). Name and dose
    // are not touched here — they come from phone settings.
    static function putSchedule(medId as Number, times as Array<Number>, days as Number, enabled as Boolean) as Void {
        var meds = loadMeds();
        for (var i = 0; i < meds.size(); i++) {
            if ((meds[i]["id"] as Number) == medId) {
                meds[i]["times"] = times;
                meds[i]["days"] = days;
                meds[i]["enabled"] = enabled;
                saveMeds(meds);
                return;
            }
        }
    }

    static function removeMed(medId as Number) as Void {
        var meds = loadMeds();
        var out = [] as Array<Dictionary>;
        for (var i = 0; i < meds.size(); i++) {
            if ((meds[i]["id"] as Number) != medId) {
                out.add(meds[i]);
            }
        }
        saveMeds(out);
    }

    // ---- phone settings import ----

    // Null-safe property read. Properties defined in properties.xml carry
    // defaults, but a sync mid-write can transiently return null, so we guard.
    static function propStr(key as String) as String {
        var v;
        try { v = Application.Properties.getValue(key); } catch (ex) { v = null; }
        return (v == null) ? "" : (v as String);
    }

    // Merge the phone slots into the watch-owned med list. Each slot carries only
    // Name and Dose; a blank Name means an empty/disabled slot and is skipped.
    // For a slot whose med already exists (matched by id = slot number), only
    // name/dose are refreshed — the watch-owned schedule (times/days/enabled) is
    // preserved. New slots get an empty default schedule, edited on the watch.
    static function importFromSettings() as Void {
        var existing = loadMeds();
        var out = [] as Array<Dictionary>;
        for (var i = 1; i <= SLOT_COUNT; i++) {
            var p = "cfgM" + i.format("%d");
            var name = strTrim(propStr(p + "Name"));
            if (name.length() == 0) {
                continue;
            }
            var dose = strTrim(propStr(p + "Dose"));
            var prior = null as Dictionary?;
            for (var k = 0; k < existing.size(); k++) {
                if ((existing[k]["id"] as Number) == i) {
                    prior = existing[k];
                    break;
                }
            }
            if (prior != null) {
                prior["name"] = name;
                prior["dose"] = dose;
                out.add(prior);
            } else {
                out.add({
                    "id" => i,
                    "name" => name,
                    "dose" => dose,
                    "freq" => "",
                    "times" => [] as Array<Number>,
                    "days" => ALL_DAYS,
                    "enabled" => true
                });
            }
        }
        saveMeds(out);
    }

    // ---- adherence log ----
    static function getStatus(medId as Number, due as Number) as Number {
        var log = Application.Storage.getValue(KEY_LOG) as Array<Dictionary>;
        if (log == null) {
            return STATUS_PENDING;
        }
        for (var i = 0; i < log.size(); i++) {
            var e = log[i];
            if ((e["m"] as Number) == medId && (e["d"] as Number) == due) {
                return e["s"] as Number;
            }
        }
        return STATUS_PENDING;
    }

    static function setStatus(medId as Number, due as Number, status as Number) as Void {
        var log = Application.Storage.getValue(KEY_LOG) as Array<Dictionary>;
        if (log == null) {
            log = [] as Array<Dictionary>;
        }
        var out = [] as Array<Dictionary>;
        var found = false;
        for (var i = 0; i < log.size(); i++) {
            var e = log[i];
            if ((e["m"] as Number) == medId && (e["d"] as Number) == due) {
                found = true;
                if (status != STATUS_PENDING) {
                    e["s"] = status;
                    e["a"] = Time.now().value();
                    out.add(e);
                }
                // PENDING => drop the entry entirely
            } else {
                out.add(e);
            }
        }
        if (!found && status != STATUS_PENDING) {
            out.add({ "m" => medId, "d" => due, "s" => status, "a" => Time.now().value() });
        }
        Application.Storage.setValue(KEY_LOG, out);
    }

    static function pruneLog() as Void {
        var log = Application.Storage.getValue(KEY_LOG) as Array<Dictionary>;
        if (log == null) {
            return;
        }
        var cutoff = Time.now().value() - LOG_RETENTION_DAYS * 86400;
        var out = [] as Array<Dictionary>;
        for (var i = 0; i < log.size(); i++) {
            if ((log[i]["d"] as Number) >= cutoff) {
                out.add(log[i]);
            }
        }
        Application.Storage.setValue(KEY_LOG, out);
    }

    // ---- derived views ----

    // weekday bit for a given midnight Moment (day_of_week: 1=Sun..7=Sat)
    static function dayBit(midnightMoment as Time.Moment) as Number {
        var info = Gregorian.info(midnightMoment, Time.FORMAT_SHORT);
        return 1 << (info.day_of_week - 1);
    }

    // All doses scheduled for today, sorted by time, each annotated with status.
    static function todayDoses() as Array<Dictionary> {
        var meds = loadMeds();
        var midnightMoment = Time.today();
        var midnight = midnightMoment.value();
        var bit = dayBit(midnightMoment);
        var out = [] as Array<Dictionary>;
        for (var i = 0; i < meds.size(); i++) {
            var med = meds[i];
            if (med["enabled"] == false) {
                continue;
            }
            if (((med["days"] as Number) & bit) == 0) {
                continue;
            }
            var times = med["times"] as Array<Number>;
            for (var t = 0; t < times.size(); t++) {
                var minutes = times[t];
                var due = midnight + minutes * 60;
                out.add({
                    "medId" => med["id"] as Number,
                    "name" => med["name"] as String,
                    "dose" => med["dose"] as String,
                    "minutes" => minutes,
                    "due" => due,
                    "status" => getStatus(med["id"] as Number, due)
                });
            }
        }
        for (var a = 1; a < out.size(); a++) {
            var key = out[a];
            var b = a - 1;
            while (b >= 0 && (out[b]["minutes"] as Number) > (key["minutes"] as Number)) {
                out[b + 1] = out[b];
                b--;
            }
            out[b + 1] = key;
        }
        return out;
    }

    // Soonest still-pending dose for today (>= now), or null.
    static function nextDose() as Dictionary? {
        var now = Time.now().value();
        var doses = todayDoses();
        for (var i = 0; i < doses.size(); i++) {
            if ((doses[i]["status"] as Number) == STATUS_PENDING && (doses[i]["due"] as Number) >= now) {
                return doses[i];
            }
        }
        return null;
    }

    // Consecutive days (ending today) where every dose due-so-far was taken.
    // Days with no scheduled doses are neutral and don't break the streak.
    static function computeStreak() as Number {
        var meds = loadMeds();
        if (meds.size() == 0) {
            return 0;
        }
        var now = Time.now().value();
        var streak = 0;
        for (var offset = 0; offset < 366; offset++) {
            var midnightMoment = Time.today().subtract(new Time.Duration(offset * 86400));
            var midnight = midnightMoment.value();
            var bit = dayBit(midnightMoment);
            var dueCount = 0;
            var allTaken = true;
            for (var i = 0; i < meds.size(); i++) {
                var med = meds[i];
                if (med["enabled"] == false || ((med["days"] as Number) & bit) == 0) {
                    continue;
                }
                var times = med["times"] as Array<Number>;
                for (var t = 0; t < times.size(); t++) {
                    var due = midnight + times[t] * 60;
                    if (offset == 0 && due > now) {
                        continue; // hasn't come due yet today
                    }
                    dueCount++;
                    if (getStatus(med["id"] as Number, due) != STATUS_TAKEN) {
                        allTaken = false;
                    }
                }
            }
            if (dueCount == 0) {
                continue; // neutral day
            }
            if (allTaken) {
                streak++;
            } else {
                break;
            }
        }
        return streak;
    }

    // TAKEN / SKIPPED / PENDING if uniform, else PARTIAL.
    static function aggregateStatus(doses as Array<Dictionary>) as Number {
        if (doses.size() == 0) {
            return STATUS_PENDING;
        }
        var allTaken = true;
        var allSkipped = true;
        var allPending = true;
        for (var i = 0; i < doses.size(); i++) {
            var s = doses[i]["status"] as Number;
            if (s != STATUS_TAKEN) { allTaken = false; }
            if (s != STATUS_SKIPPED) { allSkipped = false; }
            if (s != STATUS_PENDING) { allPending = false; }
        }
        if (allTaken) { return STATUS_TAKEN; }
        if (allSkipped) { return STATUS_SKIPPED; }
        if (allPending) { return STATUS_PENDING; }
        return STATUS_PARTIAL;
    }

    static function setStatusForDoses(doses as Array<Dictionary>, status as Number) as Void {
        for (var i = 0; i < doses.size(); i++) {
            setStatus(doses[i]["medId"] as Number, doses[i]["due"] as Number, status);
        }
    }

    // The Today screen's display/selection model: a flat list of items, where
    // each item is a "takeall" (whole day), a "group" header (>=2 meds sharing a
    // time), or a single "dose". Group/takeall items act on all their doses.
    static function todayItems() as Array<Dictionary> {
        var doses = todayDoses(); // sorted by minutes, each annotated with status
        var items = [] as Array<Dictionary>;
        if (doses.size() == 0) {
            return items;
        }
        if (doses.size() >= 2) {
            items.add({
                "kind" => "takeall", "label" => "Take all today", "minutes" => -1,
                "doses" => doses, "status" => aggregateStatus(doses), "indent" => false
            });
        }
        var i = 0;
        while (i < doses.size()) {
            var t = doses[i]["minutes"] as Number;
            var group = [] as Array<Dictionary>;
            var j = i;
            while (j < doses.size() && (doses[j]["minutes"] as Number) == t) {
                group.add(doses[j]);
                j++;
            }
            if (group.size() >= 2) {
                items.add({
                    "kind" => "group", "label" => formatTime(t) + "  All (" + group.size().format("%d") + ")",
                    "minutes" => t, "doses" => group, "status" => aggregateStatus(group), "indent" => false
                });
                for (var k = 0; k < group.size(); k++) {
                    items.add({
                        "kind" => "dose", "label" => group[k]["name"] as String, "minutes" => t,
                        "doses" => [group[k]] as Array<Dictionary>, "status" => group[k]["status"] as Number, "indent" => true
                    });
                }
            } else {
                var d = group[0];
                items.add({
                    "kind" => "dose", "label" => formatTime(t) + "  " + (d["name"] as String), "minutes" => t,
                    "doses" => [d] as Array<Dictionary>, "status" => d["status"] as Number, "indent" => false
                });
            }
            i = j;
        }
        return items;
    }
}
