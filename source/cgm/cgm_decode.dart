// ignore_for_file: avoid_dynamic_calls, lines_longer_than_80_chars

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import '../utils/data_manager.dart';


class EncodeDecodeManager {
  bool binaryEncodeFile({required Uint8List data, required File syncFile, required FileMode mode}) {
    data = Uint8List.fromList(data.getRange(0, 12).toList());
    syncFile.writeAsBytesSync(data, mode: mode, flush: true);
    return true;
  }
  static List<CgmMeasurement> binaryDecodeData(Uint8List source, {bool fromDevice = false, int start = 0, int? end}) {
    if (end != null && start > end) {
      throw 'Please make sure start and end parameters!';
    }
    try {
      final output = <CgmMeasurement>[];
      const base = 12;
      final l = source.lengthInBytes;
      final s = start * base;
      final e = s + (end == null ? l : s + (end * base));
      final view = Uint8List.fromList(source.getRange(s, e).toList());
      final steps = view.lengthInBytes ~/ base;
      for (var i = 0; i < steps; i++) {
        final item = Uint8List.fromList(view.getRange(i * base, (i + 1) * base).toList());
        output.add(decodeHistoryItem(item, fromDevice:fromDevice));
      }
      return output;
    } catch (e) {
      print('ERROR binaryDecodeData : $e');
      return <CgmMeasurement> [];
    }
  }

  static Uint8List binaryEncode(List<CgmMeasurement> source){
    final output=<int>[];
    for (final element in source) {
      output.addAll(encodeHistoryItem(element));
    }
    return Uint8List.fromList(output);
  }
  static List<CgmMeasurement> binaryDecodeFile(File source, {int start = 0, int? end}) {
    if (end != null && start > end) {
      throw 'Please make sure start and end parameters!';
    }
    try {
      final output = <CgmMeasurement>[];
      const base = 12;
      const dl = 0;
      final l = source.lengthSync();
      // DakikHelper.log(" >>>>> asdasd ${Uint8List.fromList(source.readAsBytesSync().getRange(0, 4)).buffer.asByteData().getInt32(0)}");
      // DakikHelper.log("adim adim1 l: ${l.toInt()} - start:$start end:$end}");
      int? date;
      RandomAccessFile? ref;
      if (l > dl) {
        ref = source.openSync()..setPositionSync(0);
        // DakikHelper.log("adim adim2 ref position: ${ref.positionSync()}");
        if (dl > 0) {
          date = ByteData.view(Uint8List.fromList(ref.readSync(dl)).buffer).getInt32(0);
        }
        // DakikHelper.log("adim adim3 date: ${date}");
      }
      if (ref != null) {
        ref = source.openSync()..setPositionSync(dl + (start * base));
        // DakikHelper.log("adim adim4 ref position: ${ref.positionSync()}");
        if (end != null && (l - dl ~/ base) < end) {
          throw 'hata'; //todo bakilacak
        }
        final rl = end == null ? ((l - dl) ~/ base) : end - start;
        // DakikHelper.log("adim adim5 rl: ${rl} , ${end == null ? (l - dl) / base : end - start} start:${start}");
        for (var i = start; i < rl; i++) {
          final id = ref.readSync(base);
          // DakikHelper.log("adim adim6 id: ${id} ref position: ${ref.positionSync()}");
          output.add(decodeHistoryItem(id, fromDevice:false));
          // ref.setPositionSync(ref.positionSync() + base);
        }
      }
      return output;
    } catch (e) {
      print("ERROR binaryDecodeFile : ${e.toString()}");
      return <CgmMeasurement>[];
    }
  }
}

class OldEncodeDecodeManager {

  static bool binaryEncodeFile(Map<String, dynamic> data, File syncFile, FileMode mode) {
    final d = Uint8List(3 * 4 * data.length);
    var index = 0;
    var res = false;
    data.forEach((key, value) {
      final a = int.tryParse(value['idWithinSession'].toString());
      final b = int.tryParse(value['time'].toString().padRight(10, '0').substring(0, 10));
      final c = double.tryParse(value['value'].toString());
      if (a != null && b != null && c != null) {
        d.buffer.asInt32List()[(index * 3) + 0] = a;
        d.buffer.asInt32List()[(index * 3) + 1] = b;
        d.buffer.asInt32List()[(index * 3) + 2] = (double.parse(c.toStringAsFixed(2)) * 100).toInt();
        syncFile.writeAsBytesSync(d, mode: mode, flush: true);
        index++;
        res = true;
      } else {
        res = false;
        return;
      }
    });
    return res;
  }

  static Uint8List binaryEncodeData(Map<String, dynamic> data) {
    final d = <int>[];
    data.forEach((key, value) {
      final collection=Uint8List(12);
      final a = int.parse(value['idWithinSession'].toString());
      var b = int.parse(value['time'].toString());
      if(b.toString().length > 10){
        b=int.parse(b.toString().substring(0,10));
      }
      final c = (double.parse(double.parse(value['value'].toString()).toStringAsFixed(2)) *100).toInt();
      collection.buffer.asInt32List()[0] = a;
      collection.buffer.asInt32List()[1] = b;
      collection.buffer.asInt32List()[2] = c;
      d.addAll(collection);
    });
    return Uint8List.fromList(d);
  }

  static Map<String, dynamic> binaryDecodeData(Uint8List source, {int start = 0, int? end}) {
    final buffer = source.buffer;
    // DakikHelper.log("GOSTER binaryDecodeFile BUFFER:${buffer.asInt32List()}");
    final bytes = ByteData.view(buffer);
    final output = <String, dynamic>{};
    for (var i = start; i < (end ?? (bytes.lengthInBytes ~/ 12)); i++) {
      num totala = 0;
      totala += pow(2, 8 * 0) * bytes.getUint8(i * 12);
      totala += pow(2, 8 * 1) * bytes.getUint8((i * 12) + 1);
      totala += pow(2, 8 * 2) * bytes.getUint8((i * 12) + 2);
      totala += pow(2, 8 * 3) * bytes.getUint8((i * 12) + 3);

      num totalb = 0;
      totalb += pow(2, 8 * 0) * bytes.getUint8((i * 12) + 4);
      totalb += pow(2, 8 * 1) * bytes.getUint8((i * 12) + 5);
      totalb += pow(2, 8 * 2) * bytes.getUint8((i * 12) + 6);
      totalb += pow(2, 8 * 3) * bytes.getUint8((i * 12) + 7);
      totalb = totalb * 1000;

      num totalc = 0;
      totalc += pow(2, 8 * 0) * bytes.getUint8((i * 12) + 8);
      totalc += pow(2, 8 * 1) * bytes.getUint8((i * 12) + 9);
      totalc += pow(2, 8 * 2) * bytes.getUint8((i * 12) + 10);
      totalc += pow(2, 8 * 3) * bytes.getUint8((i * 12) + 11);
      final value=totalc.toInt() / 100;
      if (totalb.toInt() != 0) {
        final r = GluconovaHistoricalDataOutputModel(
          idWithinSession: totala.toInt(),
          time: totalb.toInt(),
          dateStr: DateTime.fromMillisecondsSinceEpoch(totalb.toInt()).toString(),
          // time: Platform.isAndroid ? totalb.toInt() : dt.millisecondsSinceEpoch,
          // dateStr:"${Platform.isAndroid ? DateTime.fromMillisecondsSinceEpoch(totalb.toInt()) : ConvertTo(DateTime.fromMillisecondsSinceEpoch(totalb.toInt())).date()}",
          value: value,
          isHistory: true,
        ).toJson();
        // DakikHelper.log("EVENTDATA: $r");
        // print({totala.toString(): r});
        output.addAll({totala.toString(): r});
      } else {
        print('corrapted data at $i');
        // break;
      }
    }
    return output;
  }

  static Map<String, dynamic> binaryDecodeFile(File source, [int start = 0, int? end]) {
    final l = source.lengthSync();
    final s = start * 12;
    final e = (end == null) ? (l - s) : ((12 * end) > (l - s) ? (l - s) : (12 * end));
    final raf = source.openSync()..setPositionSync(s);
    final buffer = raf.readSync(e).buffer;
    final bytes = ByteData.view(buffer);
    final output = <String, dynamic>{};
    for (var i = 0; i < (bytes.lengthInBytes ~/ 12); i++) {
      num totala = 0;
      totala += pow(2, 8 * 0) * bytes.getUint8(i * 12);
      totala += pow(2, 8 * 1) * bytes.getUint8((i * 12) + 1);
      totala += pow(2, 8 * 2) * bytes.getUint8((i * 12) + 2);
      totala += pow(2, 8 * 3) * bytes.getUint8((i * 12) + 3);

      num totalb = 0;
      totalb += pow(2, 8 * 0) * bytes.getUint8((i * 12) + 4);
      totalb += pow(2, 8 * 1) * bytes.getUint8((i * 12) + 5);
      totalb += pow(2, 8 * 2) * bytes.getUint8((i * 12) + 6);
      totalb += pow(2, 8 * 3) * bytes.getUint8((i * 12) + 7);
      totalb = totalb * 1000;

      num totalc = 0;
      totalc += pow(2, 8 * 0) * bytes.getUint8((i * 12) + 8);
      totalc += pow(2, 8 * 1) * bytes.getUint8((i * 12) + 9);
      totalc += pow(2, 8 * 2) * bytes.getUint8((i * 12) + 10);
      totalc += pow(2, 8 * 3) * bytes.getUint8((i * 12) + 11);

      if (totalb.toInt() != 0) {
        final r = GluconovaHistoricalDataOutputModel(
          idWithinSession: totala.toInt(),
          time: totalb.toInt(),
          dateStr: DateTime.fromMillisecondsSinceEpoch(totalb.toInt()).toString(),
          value: totalc.toInt() / 100,
          isHistory: true,
        ).toJson();
        // DakikHelper.log("EVENTDATA: $r");
        output.addAll({totala.toString(): r});
      } else {
        print('corrapted data at $i');
      }
    }
    return output;
  }
}
