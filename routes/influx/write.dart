// ignore_for_file: lines_longer_than_80_chars
import 'dart:async';
import 'dart:convert';
import 'package:dart_frog/dart_frog.dart' as frog;
// import 'package:influxdb_client/api.dart';

// InfluxDBClient? influx;

Future<frog.Response> onRequest(frog.RequestContext context) async {
  // Access the incoming request.
  final request = context.request;
  final body = await request.body();
  Map<String,dynamic>? response;
  try {
    // final writeApi= influx?.getWriteService(
    //   WriteOptions().merge(
    //     batchSize: 10000,
    //     flushInterval: 1000,
    //     retryJitter: 200,
    //     retryInterval: 5000,
    //     maxRetryDelay: 125000,
    //     maxRetryTime: 180000,
    //     exponentialBase: 2,
    //     maxRetries: 5,
    //     maxBufferLines: 1000000,
    //     precision: WritePrecision.ns,
    //     gzip: false,
    //   ),
    // );
    if(body.isNotEmpty){
      final data= List<Map<String,dynamic>>.from(jsonDecode(body) as List);
      var index=0;
      await Future.forEach(data, (element) async {
        try {
          final measurement=element['measurement']?.toString();
          final time= DateTime.tryParse(element['time'].toString());
          final value= element['value'];
          if(measurement != null && value != null && time != null){
            // final point=Point(measurement).addField('value', value).time(time);
            // element.keys.where((element) => !['measurement','time','value'].contains(element)).forEach((e) {
            //   point.addTag(e, element[e].toString());
            // });
            // await writeApi?.write(point).catchError((ex) => print('>>>> WriteApi Error: $ex'));
            index++;
          }else{
            response??={'success':true, 'data':'check data types $measurement $time $value'};
          }
        } catch (e) {
          print('>>>> error1 $e');
        }
      });
      response??={'success':true, 'data':'${data.length}/$index'};
    }
  } catch (e) {
    print('>>>> error2 $e');
    response??={'success':false, 'data':e};
  }
  print(response ?? {});
  return frog.Response(body: jsonEncode(response ?? {}),headers: {'Content-Type':'application/json'});
}
