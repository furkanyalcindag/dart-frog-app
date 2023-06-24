// ignore_for_file: lines_longer_than_80_chars, inference_failure_on_instance_creation
import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart' as dio;
extension ToMap<T> on Iterable<Map<String, T>> {
  Map<String, T> toMap() {
    final data = <String, T>{};
    for (final element in this) {
      data.addAll(element);
    }
    return data;
  }
}

final dioClient = dio.Dio();
final devUrl = 'https://mehmet-api.cpiss.org';
final apiUrl = 'https://api.map2heal.com';
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

class FileStreamObject{
  FileStreamObject({
    required this.file,
    required this.streamController,
    required this.sid,
    required this.sn,
    required this.own,
    this.timer,
    this.min,
    this.max,
    this.count,
    this.start,
    // this.end,

  }){
    if(!file.existsSync()){
      file.createSync();
    }
    fileWSink=file.openWrite();
    fileWSink!.addStream(streamController.stream);
    timer=Timer(const Duration(hours: 6), () {
      FileCollector.closeStream(sid:sid);
    });
  }

  DateTime? get end{
    return start?.add(Duration(milliseconds: (count?.toInt()?? 0) *8));
  }
  bool get isSync{
    return sid.toLowerCase().startsWith('sync');
  }
  StreamController<Uint8List> streamController;
  File file;
  String sid;
  String sn;
  String own;
  Timer? timer;
  IOSink? fileWSink;
  num? min;
  num? max;
  num? count;
  DateTime? start;
  // DateTime? end;
  Map<String,dynamic> toJson(){
    return{
      'file':file.path,
      'isSync':isSync,
      'sid':sid,
      'sn':sn,
      'own':own,
      'timer':timer?.isActive ?? false,
      'fileWSink':fileWSink != null,
      'min':min,
      'max':max,
      'count':count,
      'start':start,
      'end':end,
    };
  }
    @override
    String toString(){
      return toJson().toString();
    }
  Future<bool> closeStream() async {
    try {
      if(!streamController.isClosed){
        await streamController.close();
        timer?.cancel();
        timer=null;
        return true;
      }
      return false;
    } catch (e) {
      // print('$e');
      return false;
    }
  }
  Future<void> dispose() async {
    if(!streamController.isClosed){
      await closeStream();
    }
    timer?.cancel();
    file.deleteSync();
    FileCollector.fileStreamObjects.remove(sid);
  }
  Future<bool> sendFile() async {
    if(!streamController.isClosed){
      await closeStream();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    final token= await dioClient.get(
      '$apiUrl/remote-patient/external/get-token-by-remote-patient?id=$own',
      options: dio.Options(
        headers: {
          'x-locale': 'en-gb',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'x-api': 'v7',
          'x-encrypted': 0,
        },
      ),
    ).then((value) {
      return value.statusCode == 200 ? value.data?['data']?['apiToken'].toString() : null;
    })
    .catchError((dynamic error) {
      if (error is dio.DioError) {
        print('$apiUrl/remote-patient/external/get-token-by-remote-patient?id=$own');
        print("Error Message>>>>dio ${error.type}");
        print("Error Message>>>>dio ${error.message}");
        print("Error Message>>>>dio ${error.response?.statusMessage}");
        print("Error Message>>>>dio ${error.response?.data}");
        return error.message;
      } else {
        print("Error Message>>>> ${error}");
        return error.toString();
      }
    });
    print('token >>> $token');
    final fl=file.lengthSync();
    print('file length: $fl');
    if(!(fl>0)){
      print('file is empty');
    }
    if(token !=null){
      return dioClient.post<Map<String, dynamic>>(
        '$apiUrl/remote-patient/external/create-measurement',
        options: dio.Options(
          headers: {
            'authorization': 'Bearer $token',
            'x-locale': 'en-gb',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'x-api': 'v7',
            'x-encrypted': 0,
          },
        ),
        data: dio.FormData.fromMap(
          {
            'dataFile': dio.MultipartFile.fromFileSync(file.path, filename: 'rp_${own}_$sid.dat'),
            'RemotePatientMeasurement': <String, dynamic>{
              'remote_patient_id': own,
              'remote_patient_loinc_num': '71575-5',
              'data': isSync ? 'ECG-Sync' : 'ECG-Stream',
              'param': 'binary',
              'uuid': sid,
              'data_float': count,
              'forceUpdate': 1,
              'addAttributes': [
                if(isSync) {
                  'RemotePatientMeasurementAttribute': {'type': 'number','name': 'ecgSync','hidden': 1,'value': '1',}
                },
                {
                  'RemotePatientMeasurementAttribute': {'type': 'number','name': 'xScaleFactor','hidden': 1,'loinc': '71575-5','value': sn.toUpperCase().startsWith('HC02') ? '0.25' : '1',}
                },
                {
                  'RemotePatientMeasurementAttribute': {'type': 'number','name': 'yScaleFactor','hidden': 1,'loinc': '71575-5','value': '1.0',}
                },
                {
                  'RemotePatientMeasurementAttribute': {'type': 'number','name': 'centerPoint','hidden': 1,'loinc': '71575-5','value': '0',}
                },
                {
                  'RemotePatientMeasurementAttribute': {'type': 'string', 'name': 'deviceIdentity', 'hidden': 0, 'value': sn.toUpperCase()}
                },
                if (start != null)
                  {
                    'RemotePatientMeasurementAttribute': {'type': 'datetime', 'name': 'startDate', 'hidden': 0, 'value': start}
                  },
                if (end != null)
                  {
                    'RemotePatientMeasurementAttribute': {'type': 'datetime', 'name': 'endDate', 'hidden': 0, 'value': end}
                  },
                if (min != null)
                  {
                    'RemotePatientMeasurementAttribute': {'type': 'number', 'name': 'min', 'hidden': 0, 'value': min}
                  },
                if (max != null)
                  {
                    'RemotePatientMeasurementAttribute': {'type': 'number', 'name': 'max', 'hidden': 0, 'value': max}
                  },
                if (count != null)
                  {
                    'RemotePatientMeasurementAttribute': {'type': 'number', 'name': 'count', 'hidden': 0, 'value': count}
                  },
              ]
            }
          },
        ),
      ).then((value) async {
        print(value.data);
        await dispose();
        return value.data?['success'] == true;
      }).catchError((dynamic error) {
      if (error is dio.DioError) {
        print('$apiUrl/remote-patient/external/create-measurement');
        print("Error Message>>>>dio ${error.type}");
        print("Error Message>>>>dio ${error.message}");
        print("Error Message>>>>dio ${error.response?.statusMessage}");
        print("Error Message>>>>dio ${error.response?.data}");
        return error.message;
      } else {
        print("Error Message>>>> ${error}");
        return error.toString();
      }
    });
    }
    return false;


  }

}
class FileCollector{
  static final directory = (Directory.current..createSync()).path;

  static final fileStreamObjects = <String,FileStreamObject>{};
  // static final fileStreamTimes = <String,DateTime>{};
  // static final fileStreamControllers = <String,StreamController<Uint8List>>{};
  static FileStreamObject? getFileStreamObject(String key){
    return fileStreamObjects[key];
  }
  static Future<bool> closeStream({required String sid}) async {
    if(getFileStreamObject(sid) != null){
      return  getFileStreamObject(sid)!.closeStream();
    }
    return false;
  }

  static bool addStream({required String sid,required String own,required String sn,required Uint8List data}) {
    // print('???? ${getFileStreamObject(sid)}');
    if(getFileStreamObject(sid) == null){
      fileStreamObjects.addAll({
        sid:FileStreamObject(
          file: File('$directory/$sid.dat'), 
          own: own,
          sid: sid,
          sn: sn,
          streamController: StreamController<Uint8List>.broadcast(
            sync: true,
            onCancel: (){
              print('$sid stream canceled');
            },
          ),
        )
      });
    }
    final so=getFileStreamObject(sid);
    so?.streamController.add(data);
    // print(getFileStreamObject(sid)?.file.lengthSync());
    return so !=null;
  }
}


 class CgmMeasurement {
  
  CgmMeasurement({
     required this.healthy,
     required this.raw,
     required this.cFlag,
     required this.lenght,
     required this.flags,
     required this.concentration,
     required this.sequenceNumber,
     required this.s1,
     required this.s2,
     required this.s3,
     required this.isHistory,
     required this.trend,
     required this.quality,
     this.crc,
  });
     Uint8List raw;
     List<int> cFlag;
     int lenght;
     List<int> flags;
     double concentration;
     int sequenceNumber;
     int s1;
     int s2;
     int s3;
     bool isHistory;
     int trend;
     double quality;
     Uint8List? crc;
     bool healthy;
  DateTime getDateTime(DateTime startDate,DeviceEnum deviceType) => startDate.add(Duration(minutes: (sequenceNumber * 3)+(deviceType == DeviceEnum.i3? 7 : 0)+3));
  Map<String, dynamic> toJson() => {
     'raw':raw.toList(), //Uint8List
     'cFlag':cFlag.toList(), //List<int>
     'lenght':lenght, //int
     'flags':flags.toList(), //List<int>
     'health':healthy, //double
     'concentration':concentration, //double
     'sequenceNumber':sequenceNumber, //int
     's1':s1, //int
     's2':s2, //int
     's3':s3, //int
     'isHistory':isHistory, //bool
     'trend':trend, //int
     'quality':quality, //double
     'crc':crc?.toList(), //Uint8List?
  };

    @override
  String toString() {
    return 'CgmMeasurement: ${toJson()}';
  }
}
enum DeviceEnum { iris, i3, p3, mirhythm, hc03, undefined }

 class GluconovaHistoricalDataOutputModel {

  factory GluconovaHistoricalDataOutputModel.fromJson(Map<String, dynamic> json) => GluconovaHistoricalDataOutputModel(
        quality: json['quality'] == null ? null : double.parse(json['quality'].toString()),
        trend: json['trend'] == null ? null : int.parse(json['trend'].toString()),
        time: json['time'] == null ? null : int.parse(json['time'].toString().padRight(13, '0')),
        dateStr: json['dateStr']?.toString(),
        value: json['value'] == null ? null : double.parse(json['value'].toString().substring(0, json['value'].toString().length < 6 ? json['value'].toString().length : 6)),
        idWithinSession: json['idWithinSession'] == null ? null : int.parse(json['idWithinSession'].toString()),
        isHistory: json['isHistory'] == null ? null : json['isHistory'] as bool,
        id: json['id']?.toString(),
        discard: json['discard'] == null ? false : bool.fromEnvironment(json['discard'].toString()) ,
      );

  factory GluconovaHistoricalDataOutputModel.fromRawJson(String str) => GluconovaHistoricalDataOutputModel.fromJson(json.decode(str) as Map<String, dynamic>);
  GluconovaHistoricalDataOutputModel({
    this.time,
    this.dateStr,
    this.value,
    this.idWithinSession,
    this.isHistory,
    this.id,
    this.discard,
    this.rawData,
    this.quality,
    this.trend,
  }) {
    discard ??= false;
  }
  String? id;
  final int? time;
  final String? dateStr;
  final double? value;
  final int? idWithinSession;
  final bool? isHistory;
  final Uint8List? rawData;
  final double? quality;
  final int? trend;
  bool? discard;

  String toRawJson() => json.encode(toJson());

  Map<String, dynamic> toJson() => {
        'quality': quality,
        'trend': trend,
        'time': time,
        'dateStr': dateStr,
        'value': ConvertTo(value).doublee(),
        'idWithinSession': idWithinSession,
        'isHistory': isHistory,
        'id': id,
        'discard': discard,
        'rawData': rawData?.toList() ?? [],
      };

  @override
  String toString() {
    return toJson().toString();
  }
}

  CgmMeasurement decodeHistoryItem(Uint8List data, {bool fromDevice = false}) {
    final raw=<int>[];
    var index=0;
    int? length;
     if(fromDevice){
       length=data[index];
       index++;
     }
    //  print('>>>>> flag , $fromDevice $index');
    final flag =data[index].toRadixString(2).padLeft(8, '0').split('').reversed.map(int.parse).toList();
    raw.add(data[index]);
    index++;
    var annunciation1Exist = true;
    var annunciation2Exist = true;
    var annunciation3Exist = true;
    var trendFieldExist = true;
    var qualityExist = true;
   if(fromDevice){
    annunciation1Exist = flag[5] == 1;
    annunciation2Exist = flag[6] == 1;
    annunciation3Exist = flag[7] == 1;
    trendFieldExist = flag[0] == 1;
    qualityExist = flag[1] == 1;
   }
  final cdata=data.getRange(index, index+2).toList();
   raw.addAll(cdata);
   index=index+2;
  final cFlag=cdata[1].toRadixString(2).padLeft(8,'0').substring(0,4).split('').map(int.parse).toList();
  cdata[1]=cdata[1]&0x0F;
  final concentration = Uint8List.fromList(cdata).buffer.asByteData().getUint16(0, Endian.little)/100;
   final sdata=data.getRange(index, index+2).toList();
   raw.addAll(sdata);
  final sequenceNumber = Uint8List.fromList(sdata).buffer.asByteData().getUint16(0, Endian.little);
   index=index+2;
   int? annunciation1;
   int? annunciation2;
   int? annunciation3;
   int? trend;
   double? quality;
   final crc = fromDevice ? Uint8List.fromList(data.getRange(data.length-2,data.length).toList()) : null;
   var isHistory=false;
   if(annunciation1Exist){
     annunciation1 = data[index];
     index++;
   }
   raw.add(annunciation1 ?? 0);
   if(annunciation2Exist){
     annunciation2 = data[index];
     isHistory=annunciation2.toRadixString(2).split('').first == '1';
     index++;
   }
   raw.add(annunciation2 ?? 0);
   if(annunciation3Exist){
     annunciation3 = data[index];
     index++;
   }
   raw.add(annunciation3 ?? 0);
   if(trendFieldExist){
     trend = Uint8List.fromList(data.getRange(index,index+2).toList()).buffer.asByteData().getUint16(0,Endian.little);
     raw.addAll(data.getRange(index,index+2).toList());
     index= index+2;
   }else{
     raw.addAll([0,0]);
   }
   if(qualityExist){
     quality = Uint8List.fromList(data.getRange(index,index+2).toList()).buffer.asByteData().getUint16(0,Endian.little)/100;
     raw.addAll(data.getRange(index,index+2).toList());
     index= index+2;
   }else{
     raw.addAll([0,0]);
   }
   return CgmMeasurement (
     raw:Uint8List.fromList(raw),
     cFlag:cFlag,
     healthy: (quality ?? 0) > 0.1 && (quality ?? 0) <= 50,
     lenght:length ?? data.length,
     flags:flag,
     concentration:concentration,
     sequenceNumber:sequenceNumber,
     s1:annunciation1 ?? 0,
     s2:annunciation2 ?? 0,
     s3:annunciation3 ?? 0,
     isHistory:isHistory,
     trend:trend ?? 0,
     quality:quality ?? 0,
     crc:crc
   );
 }
  Uint8List encodeHistoryItem(CgmMeasurement data) {
    final intList=<int>[int.parse(data.flags.map((e)=>e.toString()).toList().reversed.toList().join(),radix:2)];
    final cdata=(ByteData(2)..setInt16(0,(data.concentration*100).round())).buffer.asUint8List().reversed.toList();
    final intData=<int>[];
//     print(cdata[1].toRadixString(2).padLeft(8,'0').split('').asMap());
    cdata[1].toRadixString(2).padLeft(8,'0').split('').asMap().forEach((i,e){
      if(i > data.cFlag.length-1){
        intData.add(int.parse(e));
      }else{
        intData.add(data.cFlag[i]);
      }
    });
    cdata[1]=int.parse(intData.join(),radix:2);
    intList
    ..addAll(cdata)
    ..addAll((ByteData(2)..setInt16(0,data.sequenceNumber)).buffer.asUint8List().reversed.toList())
    ..add(data.s1)
    ..add(data.s2)
    ..add(data.s3)
    ..addAll((ByteData(2)..setInt16(0,data.trend)).buffer.asUint8List().reversed.toList())
    ..addAll((ByteData(2)..setInt16(0,(data.quality*100).round())).buffer.asUint8List().reversed.toList());
    return Uint8List.fromList(intList);
  }



class ConvertTo {
  ConvertTo(this.data);
  dynamic data;

  int? integer() {
    try {
      if (data.runtimeType == int) {
        return data as int;
      } else if (data.runtimeType == double) {
        return (data as double).floor();
      } else if (data is bool) {
        return (data as bool) ? 1 : 0;
      } else {
        return int.tryParse(data.toString());
      }
    } catch (e) {
      return null;
    }
  }

  double? doublee() {
    try {
      if (data.runtimeType == double) {
        return data as double;
      } else if (data.runtimeType == int) {
        return (data as int).toDouble();
      } else {
        if (data.runtimeType == String) {
          data = (data as String).replaceAll(',', '.');
        }
        return double.tryParse(data.toString());
      }
    } catch (e) {
      return null;
    }
  }

  num? number() {
    try {
      if (data.runtimeType == num) {
        return data as num;
      } else {
        return num.tryParse(data.toString());
      }
    } catch (e) {
      return null;
    }
  }

  bool? boolean([bool canBeNull = false]) {
    try {
      if (data.runtimeType == bool) {
        return data as bool;
      } else if (canBeNull && data == null) {
        return null;
      } else if (data.runtimeType == String) {
        if(int.tryParse(data.toString()) == 1){
          return true;
        }else if (data == null) {
          return canBeNull ? null : false;
        } else {
          if (data.toString().trim().toLowerCase() == 'true') {
            return true;
          } else if (data.toString().trim().toLowerCase() == 'false') {
            return false;
          } else {
            return canBeNull ? null : false;
          }
        }
      }
      final a = integer();
      if (a == 1) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  DateTime createDate([bool utcIn = false, bool? utcOut = true]) {
    DateTime date;
    if (utcIn) {
      date = DateTime.utc((data as DateTime).year, (data as DateTime).month, (data as DateTime).day, (data as DateTime).hour, (data as DateTime).minute, (data as DateTime).second, (data as DateTime).millisecond);
    } else {
      date = DateTime((data as DateTime).year, (data as DateTime).month, (data as DateTime).day, (data as DateTime).hour, (data as DateTime).minute, (data as DateTime).second, (data as DateTime).millisecond);
    }
    if (utcOut == null) {
      return date;
    } else if (utcOut) {
      return date.toUtc();
    } else {
      return date.toLocal();
    }
  }

  DateTime? date([bool utcIn = false, bool? utcOut = true]) {
    try {
      if (data.runtimeType == DateTime) {
        data = createDate(utcIn, utcOut);
        return data as DateTime;
      } else {
        data = DateTime.tryParse(data.toString());
        final date = createDate(utcIn, utcOut);
        return date;
      }
    } catch (e) {
      if (data.toString().contains('\'expression\': \'NOW()\'')) {
        return DateTime.now().toUtc();
      }
      return null;
    }
  }

  DateTime? serverDate() {
    try {
      return createDate();
    } catch (e) {
      return null;
    }
  }

  String? serverDateString() {
    try {
      final date = createDate();
      return date.toString().substring(0, 19);
    } catch (e) {
      return null;
    }
  }

  DateTime? localDate() {
    try {
      return date(true, false);
    } catch (e) {
      return null;
    }
  }

  //json['seenAt'] == null ? [] : List<SeenAtModel>.from(json["seenAt"].map((x) => SeenAtModel.fromJson(x)))
  /*List<T>? list<T>() {
    return data == null ? null : List<T>.from((T as dynamic).map((x) => (T as dynamic).fromJson(x)));
  }*/
}

enum TextCase {
  camelCase,
  constantCase,
  sentenceCase,
  snakeCase,
  dotCase,
  paramCase,
  pathCase,
  pascalCase,
  headerCase,
  titleCase,
}

