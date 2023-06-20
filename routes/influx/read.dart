// ignore_for_file: lines_longer_than_80_chars
import 'dart:async';
import 'dart:convert';
import 'package:dart_frog/dart_frog.dart' as frog;
// import 'package:influxdb_client/api.dart';
// import 'package:intl/intl.dart';
// import '../../utils/dbClients.dart';

// InfluxDBClient? influx;

Future<frog.Response> onRequest(frog.RequestContext context) async {
  // Access the incoming request.
  final request = context.request;
  final params = request.uri.queryParameters;
  // final length=(headers['content-length'] ?? '').length;
  List<Map<String?, dynamic>> response=[];
  final startTs= int.tryParse(params['start']?.toString() ?? '');
  final endTs= int.tryParse(params['end']?.toString() ?? '');
  final typ= params['typ']?.toString();
  if(startTs != null && typ != null){
    final startTime= DateTime.fromMillisecondsSinceEpoch(startTs);
    final endTime= endTs != null ? DateTime.fromMillisecondsSinceEpoch(endTs*1000) : DateTime.now();
    final sn= params['sn']?.toString();
    final own= params['own']?.toString();
    final sid= params['sid']?.toString();

    // influx ??= DbInt.influxDBClient;
    //   final queryService = influx?.getQueryService();
    //   final q = '''
    //     from(bucket: "healtm")
    //     |> range(start: ${DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(startTime)}, stop: ${DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(endTime)})
    //     |> filter(fn: (r) => r["_measurement"] == $typ)
    //     |> filter(fn: (r) => r["_field"] == "value")
    //     ${own == null ? '' : '|> filter(fn: (r) => r["owner"] == "$own")'}
    //     ${sn == null ? '' : '|> filter(fn: (r) => r["sn"] == "$sn")'}
    //     ${sid == null ? '' : '|> filter(fn: (r) => r["session"] == "$sid")'}
    //     |> aggregateWindow(every: 1ms, fn: mean, createEmpty: false)
    //   ''';
    //   print(q);
    //   final res=await queryService?.query(q).then((value) async => value.toList());
    //   res?.forEach((element) {
    //     final map = <String?, dynamic>{};
    //     for (final e in element.entries) {
    //       if (['_time', '_value', '_measurement', 'owner', 'session', 'sn','_sequence','_trend','_quality'].contains(e.key)) {
    //         map.addAll({e.key?.replaceAll('_', ''): e.value});
    //       }
    //     }
    //     response.add(map);
    //   });
  }
  return frog.Response(body: jsonEncode(response),headers: {'Content-Type':'application/json'});
}
