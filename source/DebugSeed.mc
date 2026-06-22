import Toybox.Lang;
import Toybox.Time;

// TEMPORARY: seeds sample meds + a few days of history so the simulator shows a
// realistic Today list, time grouping, take-all, status colors, and a streak.
// Flip DEBUG_SEED to false (or delete this file and its call in
// MedMinderApp.onStart) before shipping.
const DEBUG_SEED = false;

class DebugSeed {
    static function run() as Void {
        if (!DEBUG_SEED) {
            return;
        }
        if (MedStore.loadMeds().size() > 0) {
            return; // already seeded / has real data
        }
        // 8 meds (> the 6 phone slots, to show unlimited). Several share a time
        // so Today forms groups; Ibuprofen has no times (reference-only) and so
        // appears on the medicine list but not on Today.
        MedStore.upsert("Metformin", "500mg", "", [480, 1200] as Array<Number>, ALL_DAYS, true);
        MedStore.upsert("Aspirin", "81mg", "", [480] as Array<Number>, ALL_DAYS, true);
        MedStore.upsert("Lisinopril", "25mg", "3x a day", [480, 840, 1200] as Array<Number>, ALL_DAYS, true);
        MedStore.upsert("Vitamin D", "2000 IU", "", [540] as Array<Number>, ALL_DAYS, true);
        MedStore.upsert("Omega-3", "1000mg", "", [540] as Array<Number>, ALL_DAYS, true);
        MedStore.upsert("Atorvastatin", "20mg", "Bedtime", [1290] as Array<Number>, ALL_DAYS, true);
        MedStore.upsert("Magnesium", "200mg", "", [1290] as Array<Number>, ALL_DAYS, true);
        MedStore.upsert("Ibuprofen", "200mg", "As needed", [] as Array<Number>, ALL_DAYS, true);

        // Two prior full days all-taken + today's morning groups taken => streak.
        takeDay(2, false);
        takeDay(1, false);
        takeDay(0, true); // morning only; leaves evening doses pending for the demo
    }

    // Mark doses taken for the day `offset` days ago. If morningOnly, only doses
    // at or before 09:00 are marked (the rest stay pending).
    static function takeDay(offset as Number, morningOnly as Boolean) as Void {
        var meds = MedStore.loadMeds();
        var midnight = Time.today().subtract(new Time.Duration(offset * 86400)).value();
        for (var i = 0; i < meds.size(); i++) {
            var times = meds[i]["times"] as Array<Number>;
            for (var t = 0; t < times.size(); t++) {
                if (morningOnly && times[t] > 540) {
                    continue;
                }
                MedStore.setStatus(meds[i]["id"] as Number, midnight + times[t] * 60, STATUS_TAKEN);
            }
        }
    }
}
