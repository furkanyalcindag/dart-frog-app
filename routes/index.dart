import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_frog/dart_frog.dart';
import 'package:path/path.dart' as path;
import 'package:collection/collection.dart';
import '../source/ecg/ecg_decode.dart';

Future<Response> onRequest(RequestContext context) async {
//   final file=File('${path.current}/afa8b29156d669f953c2d9afdc5966de.dat');
//   var lastDate=DateTime.parse('2023-04-14 11:16:30.912Z');


// final data=file.readAsBytesSync();
//   final totalCount=(data.lengthInBytes~/13);
//   var pointCount=0;
//   var count=0;
//   var percent=0;
//   var dd='';
//   var min= double.infinity;
//   var max= double.negativeInfinity;
//   final liveBuffer=<Map<String,dynamic>>[];
//   EcgCoder.decode(
//     sid:'test',
//     dataSource: data,
//     transitionType:TransitionOsEnum.file,
//     startTime:lastDate=lastDate.add(Duration(milliseconds: 8*8)),
//   ).listen((event) async {
//     List<int> def1=[];
//     List<int> def2=[];
//     // final Map<int, EcgData> cacheData={};
//     // final EcgFrame? manipulated;
//     final encoded=await event.encode(transitionType: TransitionOsEnum.file);
//     // encoded
//     await EcgCoder.decode(sid: 'asdasdasdad', dataSource: encoded, transitionType: TransitionOsEnum.file).toList().then((value){
//       value.forEach((element) {
//        element.data.values.forEach((e) {
//          def1.add(e.value); 
//        });
//       },);
      
//     });
//     final nPercent= ((count*100)/totalCount).round();
//     if(nPercent != percent){
//       print('${nPercent-1}%');
//     }
//     event.data.values.map((e) {
//       // liveBuffer.add(e.toJson());
//       // cacheData.addAll({pointCount:EcgData(isLead:false,value:e.value)});
//       // EcgFrame(data:cacheData).
//       pointCount++;
//       return e.value;
//     }).forEach((element) {
//         def2.add(element);
//         if(element > max){
//           max=element.toDouble();
//         }
//         if(element < min){
//           min=element.toDouble();
//         }
//     });
//     var a=jsonEncode(def1.mapIndexed((index, element) => {index.toString():element}).toList());
//     var b=jsonEncode(def2.mapIndexed((index, element) => {index.toString():element}).toList());
//     if(a !=  b){
//       print('decoded a >> $a');
//       print('decoded b >> $b');
//     }


//     percent=nPercent;
//     count++;
//   },onDone: (){
//     dd='min:$min max:$max count:$count';
//     print('${100}%');
//     print('done!');
//     print(dd);
//   });
  // return Response(body: dd);
  return Response(body: 'Welcome to BLE-BIN Rest API Service');
}
