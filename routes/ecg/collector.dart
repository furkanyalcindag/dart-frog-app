// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:dart_frog/dart_frog.dart' as frog;
import 'package:path/path.dart';

import '../../source/ecg/ecg_decode.dart';
import '../../source/utils/data_manager.dart';

Future<frog.Response> onRequest(frog.RequestContext context) async {
  // Access the incoming request.
  final request = context.request;
  final params = request.uri.queryParameters;
  final device = params['device']?.toString();
  final action = params['action']?.toString();
  final sid = params['sid']?.toString();
  var status = 422;
  var res=jsonEncode({
    'success':false,
    'errors':{'message':'Invalid parametter usage "action" and "sid" must be given as url parametter'}
  });


  if(action == 'collect' && sid != null){
    try {
      final output=<int>[];
      final source=(jsonDecode(await request.body()) as List<dynamic>?) ?? [];
        final ecgItemcache=<EcgData>[];
        String? sn;
        String? own;
        var min=double.infinity;
        var max=double.negativeInfinity;
        int? start;
        int? end;
        source.forEachIndexed((index, element) {
          final itemMap=element as Map<String, dynamic>;
          final value = num.tryParse(itemMap['val'].toString())?.toInt();
          sn ??= itemMap['sn']?.toString();
          own ??= itemMap['own']?.toString();
          final isLead = itemMap['isLead'].toString().toLowerCase() == 'true';
          final ts = int.tryParse(itemMap['ts'].toString());

          if(value != null && max < value){
            max=value.toDouble();
          }
          if(value != null && min > value){
            min=value.toDouble();
          }

          start??=ts;
          end??=ts;

          if(ts != null && end! < ts){
            end=ts;
          }
          if(ts != null && start! > ts){
            start=ts;
          }
          // print('$value,$isLead');
          if(value != null){
            ecgItemcache.add(EcgData(isLead: isLead,value:value));
          }
          // print(ecgItemcache.length);
          if(ecgItemcache.length % 8 == 0){
            output.addAll(EcgFrame(data: List.generate(ecgItemcache.length, (indx) => ecgItemcache[indx]).asMap()).encode(transitionType: TransitionOsEnum.file));
            ecgItemcache.clear();
          }
        });
        ecgItemcache.clear();
        if(sn !=null && own != null){
          if(FileCollector.addStream(sid: sid, own: own!, sn: sn!, data: Uint8List.fromList(output),)){
            FileCollector.getFileStreamObject(sid)?.count=(FileCollector.getFileStreamObject(sid)?.count??0)+1;

            FileCollector.getFileStreamObject(sid)?.max ??=max;
            FileCollector.getFileStreamObject(sid)?.min ??=min;

            if(FileCollector.getFileStreamObject(sid)!.max! < max){
              FileCollector.getFileStreamObject(sid)!.max=max;
            }
            if(FileCollector.getFileStreamObject(sid)!.min! > min){
              FileCollector.getFileStreamObject(sid)!.min=min;
            }
            final cstart=DateTime.fromMicrosecondsSinceEpoch(start!);
            if(FileCollector.getFileStreamObject(sid)?.start?.isAfter(cstart) ?? true){
              FileCollector.getFileStreamObject(sid)?.start=cstart;
            }
            // final cend=DateTime.fromMicrosecondsSinceEpoch(end!);
            // if(FileCollector.getFileStreamObject(sid)?.end?.isBefore(cend) ?? true){
            //   FileCollector.getFileStreamObject(sid)?.end=cend;
            // }
          }
        }
        status=200;
        res=jsonEncode({
          'success':true,
          'response':base64Encode(output)
        });
    } catch (e) {
      res=jsonEncode({
        'success':false,
        'errors':{'message':'Request body gecersiz1 >> $e'}
      });
    }
  }else if(action == 'publish'){
    try {
      await FileCollector.closeStream(sid: sid!);
      final success=await FileCollector.getFileStreamObject(sid)?.sendFile() ?? false;
      if(success){
        await FileCollector.getFileStreamObject(sid)?.dispose();
      }
      status=200;
      res=jsonEncode({
        'success':success,
        'response':success ? 'done!' : 'fail!'
      });
    } catch (e,s) {
      res=jsonEncode({
        'success':false,
        'errors':{'message':'Request body gecersiz2 >> $e,$s'}
      });
    }
  }
  else if(action == 'dispose'){
    try {
      await FileCollector.getFileStreamObject(sid!)?.dispose();
      status=200;
      res=jsonEncode({
        'success':true,
        'response':'done!'
      });
    } catch (e,s) {
      res=jsonEncode({
        'success':false,
        'errors':{'message':'Request body gecersiz2 >> $e,$s'}
      });
    }
  }


  return frog.Response(body: res,headers: {'Content-Type':'application/json'},statusCode: status);
}
