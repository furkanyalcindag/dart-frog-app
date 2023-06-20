// ignore_for_file: public_member_api_docs, lines_longer_than_80_chars, avoid_dynamic_calls

import 'dart:async';
import 'dart:ffi';
import 'dart:ffi'as ffi;
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;

class RangePointer{
  RangePointer({required this.start,required this.end});
  int start;
  int end;
}
class EcgCoder {
  static List<int> decodeEcgVals(int v1, int v2, int v3) {
    final d1 = ((v1 & 0xFF) | ((v2 & 0x0F) << 8)) - (2048);
    final d2 = (((v2 & 0xF0) >> 4) | ((v3 & 0xFF) << 4)) - (2048);
    return [d1, d2];
  }
  static int? convertDatToRR(String datFilePath, String rrFilePath){
    final soFile= File('${path.current}/source/ecg/libMirhythm.so');
    final ffi.DynamicLibrary? init;
    if (soFile.existsSync()) {
      init=ffi.DynamicLibrary.open(soFile.path);
        final myCFunction = init.lookupFunction<ffi.Int Function(ffi.Pointer<Utf8>,ffi.Pointer<Utf8>), int Function(ffi.Pointer<Utf8>,ffi.Pointer<Utf8>)>('ConvertDatToRR');
        return myCFunction.call(datFilePath.toNativeUtf8(),rrFilePath.toNativeUtf8());
    }
    return null;
  }
  static List<int> encodeEcgVals(int d1, int d2) {
    final fd1 = (d1 + (2048)) & 4095;
    final fd2 = (d2 + (2048)) & 4095;
    final set1 = [fd1 & 0xFF, ((fd1 >> 8) & 0x000F) | ((fd2 & 0xFF) << 4), (fd2 >> 4) & 0xFF];
    return set1;
  }
  static int totalCountFromFile({required File file}){
    return file.lengthSync()~/13 * 8;
  }
  static int totalCountFromList({required Uint8List file}){
    return file.lengthInBytes~/13 *8;
  }
  static Future<List<int>> getSummaryIntList({required File file, required int optimizedLength}) async {

    final output=<int>[];
    if(file.existsSync()){
      final total = totalCountFromFile(file: file);
      var ex=(total/optimizedLength).floor();
      ex=ex-(ex%13);

      final pointer=await file.open();
      for (var i = 0; i < total; i++) {
        pointer.setPositionSync(i*ex);
        final data=pointer.readSync(3);
        if(data.length ==3){
          output.addAll(decodeEcgVals(data[0], data[1], data[2]));
        }else{
          break;
        }
      }


    }
    return output;
  }

  static Stream<Uint8List> encode({required List<EcgFrame> items, required TransitionOsEnum transitionType}) {
    final streamDataController = StreamController<Uint8List>.broadcast();
    // Microtask used to return stream before Stream objects
    // int? startIndex;
    Future.microtask(() async {
      final buffer = <String, List<int>>{};
      String? lastId;
      final data = items.asMap();
      data.forEach((i, e) {
        final id = '$i.${e.frameNo ?? 0}';
        if (lastId != null && lastId != id) {
          final bufferList= buffer[lastId] ?? [];
          final itemId = int.parse(lastId!.split('.').first);
          if (transitionType != TransitionOsEnum.file) {
            bufferList.add(data[itemId]?.frameNo ?? 0);
          }
          if (transitionType != TransitionOsEnum.file) {
            bufferList.add(data[itemId]?.checkSum ?? 0);
          }
          streamDataController.add(Uint8List.fromList(buffer[lastId]!));
          buffer.remove(lastId);
        }
        buffer[id] ??= <int>[];
        (buffer[id]!).addAll(e.encode(transitionType: transitionType));
        lastId = id;
      });
      if (lastId != null) {
        streamDataController.add(Uint8List.fromList(buffer[lastId]!));
        buffer.remove(lastId);
      }
      await streamDataController.close();
    });
    // Stream the object set to write file;
    return streamDataController.stream;
  }

  static final Map<String, int> _ecgTempItemIndex = {};

  static Stream<EcgFrame> decode({required String sid,required Uint8List dataSource, required TransitionOsEnum? transitionType, DateTime? startTime}) {
    
    if (_ecgTempItemIndex[sid] == null) {
      _ecgTempItemIndex.addAll({sid: 0});
    }
    var lastIndex = _ecgTempItemIndex[sid]!;
    final streamDataController = StreamController<EcgFrame>.broadcast(sync:true);
    transitionType ??= TransitionOsEnum.file;
    // set config
    late final int sec;
    late final int len;
    late final int size;
    switch (transitionType) {
      case TransitionOsEnum.ios:
        sec = 13;
        len = 13;
        size = (sec * len) + 2;
        break;
      case TransitionOsEnum.android:
        sec = 13;
        len = 18;
        size = (sec * len) + 2;
        break;
      case TransitionOsEnum.live:
        sec = 9;
        len = 1;
        size = (sec * len) + 1;
        break;
      case TransitionOsEnum.file:
        sec = 13;
        len = 1;
        size = sec * len;
        break;
    }
    final lastDate = startTime ?? DateTime.now();
    
    Future.microtask(() async {
      final output = <int, dynamic>{};
      final groups = <int, List<int>>{};
      int? lastSetKey;
      var gindex = 0;
      if(transitionType != TransitionOsEnum.live){
        for (var i = 0; i < dataSource.length / size; i++) {
          final start = i * size;
          if (dataSource.length - 1 > start) {
            final end = dataSource.length >= (start + size) ? (start + size) : dataSource.length;
          final ds=RangePointer(start:start, end: end);
          dataSource.getRange(ds.start, ds.end)
          .forEachIndexed((index, element) {
            groups[gindex] ??= [];
            groups[gindex]!.add(element);
            final ainnd = index + 1;
            if (ainnd % sec == 0) {
              if (groups[gindex]!.length == 13) {
                final leadoff = groups[gindex]!.last;
                final leads = leadoff.toRadixString(2).padLeft(8, '0').split('').reversed.toList().asMap().map((key, value) => MapEntry(key, int.parse(value) == 1));
                final items = groups[gindex]!.getRange(0, groups[gindex]!.length - 1);
                final ref = Uint8Source(Uint8List.fromList(items.toList()));
                final buffer = <num>[];
                for (var i = 0; i < items.length ~/ 3; i++) {
                  final set1 = ref.readAsList(3);
                  final d = decodeEcgVals(set1[0], set1[1], set1[2]);
                  buffer.addAll([d[0], d[1]]);
                }
                output[gindex] ??= <String, dynamic>{};
                output[gindex]['data'] ??= <Map<String,dynamic>>[];
                output[gindex]['data'] = buffer.asMap().map((key, value) {
                  final newDate = lastDate.add(Duration(milliseconds:lastIndex * 8));
                  final output = MapEntry(key, {'value': value, 'isLead': leads[key] ?? false, 'date': newDate, 'index': lastIndex});
                  lastIndex = _ecgTempItemIndex[sid] = lastIndex + 1;
                  return output;
                });
                if (transitionType == TransitionOsEnum.file) {
                  final frame = EcgFrame.fromJson(output[gindex] as Map<String, dynamic>);
                  streamDataController.add(frame);
                  output.clear();
                }
              } else if (groups[gindex]!.length == 2) {
                for (var i = lastSetKey ?? 0; i < gindex; i++) {
                  if (output[i] != null) {
                    output[i] ??= <String, dynamic>{};
                    output[i]['frameNo']  = groups[gindex]![0];
                    output[i]['checkSum'] = groups[gindex]![1];
                    final frame = EcgFrame.fromJson(output[i] as Map<String, dynamic>);
                    streamDataController.add(frame);
                  }
                }
                lastSetKey=gindex;
                output.clear();
              }
              groups.remove(gindex);
              gindex++;
            }
          });
          gindex++;
          }
        }
      }else{
        for (var i = 0; i < (dataSource.length - 2) / size; i++) {
          final start = i * size;
          final end = start+ size;
          final ds=RangePointer(start:start, end: end);
          dataSource.getRange(ds.start, ds.end)
          .forEachIndexed((index, element) {
            groups[gindex] ??= [];
            groups[gindex]!.add(element);
            final ainnd = index + 1;
            if (ainnd % sec == 0) {
              if (groups[gindex]!.length == 13) {
                final leadoff = groups[gindex]!.last;
                final leads = leadoff.toRadixString(2).padLeft(8, '0').split('').reversed.toList().asMap().map((key, value) => MapEntry(key, int.parse(value) == 1));
                final items = groups[gindex]!.getRange(0, groups[gindex]!.length - 1);
                final ref = Uint8Source(Uint8List.fromList(items.toList()));
                final buffer = <num>[];
                for (var i = 0; i < items.length ~/ 3; i++) {
                  final set1 = ref.readAsList(3);
                  final d = decodeEcgVals(set1[0], set1[1], set1[2]);
                  buffer.addAll([d[0], d[1]]);
                }
                output[gindex] ??= <String, dynamic>{};
                output[gindex]['data'] ??= <Map<String,dynamic>>[];
                output[gindex]['data'] = buffer.asMap().map((key, value) {
                  final newDate = lastDate.add(Duration(milliseconds:lastIndex * 8));
                  final output = MapEntry(key, {'value': value, 'isLead': leads[key] ?? false, 'date': newDate, 'index': lastIndex});
                  lastIndex = _ecgTempItemIndex[sid] = lastIndex + 1;
                  return output;
                });
                if (transitionType == TransitionOsEnum.file) {
                  final frame = EcgFrame.fromJson(output[gindex] as Map<String, dynamic>);
                  streamDataController.add(frame);
                  output.clear();
                }
              } else if (groups[gindex]!.length == 2) {
                for (var i = lastSetKey ?? 0; i < gindex; i++) {
                  if (output[i] != null) {
                    output[i] ??= <String, dynamic>{};
                    output[i]['frameNo']  = groups[gindex]![0];
                    output[i]['checkSum'] = groups[gindex]![1];
                    final frame = EcgFrame.fromJson(output[i] as Map<String, dynamic>);
                    streamDataController.add(frame);
                  }
                }
                lastSetKey=gindex;
                output.clear();
              }
              groups.remove(gindex);
              gindex++;
            }
          });
          gindex++;
        }
      }
      output.clear();
      unawaited(streamDataController.close().then((value) {
        _ecgTempItemIndex.remove(sid);
      }),);
    });
    return streamDataController.stream;
  }
}

class EcgData {
  EcgData({
    required this.isLead,
    required this.value,
    this.date,
    this.index,
  });
  factory EcgData.fromJson(Map<String, dynamic> json) => EcgData(
        date: json['date'] is int ? DateTime.fromMicrosecondsSinceEpoch(json['date'] as int) : DateTime.tryParse(json['date'].toString()),
        isLead: json['isLead'] as bool,
        value: json['value'] as int,
        index: json['index'] as int?,
      );
  DateTime? date;
  bool isLead;
  int value;
  int? index;
  Map<String, dynamic> toJson() => {
        'date': date.toString(),
        'isLead': isLead,
        'value': value,
        'index': index,
      };
  double get optVal => value == 0 ? 0 : value / 255;
  @override
  String toString() {
    return toJson().toString();
  }
}

class EcgFrame {
  EcgFrame({required this.data, this.frameNo, this.checkSum});

  factory EcgFrame.fromJson(Map<String, dynamic> json) => EcgFrame(
    data: (json['data'] as Map<int, Map<String, dynamic>>).map((key, value) => MapEntry(key, EcgData.fromJson(value))),
    frameNo: json['frameNo'] as int?,
    checkSum: json['checkSum'] as int?,
  );
  Map<int, EcgData> data;
  int? frameNo;
  int? checkSum;

  Uint8List encode({required TransitionOsEnum transitionType}) {
    final values = <int>[];
    final leads = <int>[];
    final buffer = <int>[];
    final size = transitionType == TransitionOsEnum.live ? 4 : 8;
    data.forEach((key, value) {
      values.add(value.value);
      leads.add(value.isLead ? 1 : 0);
      if (values.length == 2) {
        buffer.addAll(EcgCoder.encodeEcgVals(values.first, values.last));
        values.clear();
      }
      if (/*transitionType != TransitionOsEnum.file && */ leads.length == size) {
        final lead = int.parse(leads.reversed.join().padLeft(8, '0'), radix: 2);
        buffer.add(lead);
        leads.clear();
      }
    });
    if (transitionType != TransitionOsEnum.file) {
      buffer.add(frameNo ?? 0);
    }
    if (transitionType != TransitionOsEnum.file) {
      buffer.add(checkSum ?? 0);
    }
    return Uint8List.fromList(buffer);
  }

  Map<String, dynamic> toJson() => {
        'data': data.map((key, value) => MapEntry(key, value.toJson())),
        'frameNo': frameNo,
        'checkSum': checkSum,
      };
  @override
  String toString() {
    return toJson().toString();
  }
}

enum TransitionOsEnum { ios, android, live, file }

class Uint8Source {
  Uint8Source(this.data);
  Uint8List data;
  int _position = 0;
  int _oldPosition = 0;
  int _requestedPosition = 0;
  // ignore: use_setters_to_change_properties
  bool setPosition(int i) {
    _oldPosition = _position;
    _requestedPosition = i;
    if (i < 0 || data.length - 1 < i) {
      return false;
    }
    _position = i;
    return true;
  }

  int getPosition() => _position;

  Iterable<int> read(int len) {
    final output = <int>[];
    if (setPosition(getPosition() + len)) {
      output.addAll(data.getRange(_oldPosition, getPosition()));
    } else if (_requestedPosition > _oldPosition) {
      output.addAll(data.getRange(_oldPosition, data.length));
    }
    return output;
  }

  List<int> readAsList(int len) {
    return read(len).toList();
  }

  Uint8List readAsUint8List(int len) {
    return Uint8List.fromList(readAsList(len));
  }

  ByteData readAsByteData(int len, [int offest = 0]) {
    return readAsUint8List(len).buffer.asByteData(offest);
  }
}
