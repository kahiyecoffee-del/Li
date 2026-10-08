import '../../core/utils/dates.dart';
import '../models/care.dart';

/// One scheduled dose on a day.
class DoseSlot {
  const DoseSlot(this.med, this.time, this.at, {required this.taken});
  final Medication med;
  final String time;
  final DateTime at;
  final bool taken;
  String get doseId => MedDose.idFor(med.id, Dates.dayKey(at), time);
}

/// Today's doses in time order.
List<DoseSlot> dosesOn(DateTime day, List<Medication> meds, Set<String> takenIds) {
  final out = <DoseSlot>[];
  for (final m in meds.where((m) => !m.deleted && m.active)) {
    for (final t in m.times) {
      final at = DateTime(day.year, day.month, day.day, int.parse(t.substring(0, 2)), int.parse(t.substring(3)));
      out.add(DoseSlot(m, t, at, taken: takenIds.contains(MedDose.idFor(m.id, Dates.dayKey(day), t))));
    }
  }
  return out..sort((a, b) => a.at.compareTo(b.at));
}

/// Doses due now or earlier today that are not taken yet.
List<DoseSlot> dueDoses(DateTime now, List<Medication> meds, Set<String> takenIds) =>
    dosesOn(now, meds, takenIds).where((d) => !d.taken && !d.at.isAfter(now)).toList();
