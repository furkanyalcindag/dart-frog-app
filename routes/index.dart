import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_frog/dart_frog.dart';
import 'package:path/path.dart' as path;
import 'package:collection/collection.dart';
import '../source/ecg/ecg_decode.dart';

Future<Response> onRequest(RequestContext context) async {

  final file=File('${path.current}/testmintiecg.json');
  print(file.existsSync());
  final data=jsonDecode(file.readAsStringSync()) as List<dynamic>;


  List<int> encodeEcgVals(int d1, int d2) {
    final fd1 = (d1 + (2048)) & 4095;
    final fd2 = (d2 + (2048)) & 4095;
    final set1 = [fd1 & 0xFF, ((fd1 >> 8) & 0x000F) | ((fd2 & 0xFF) << 4), (fd2 >> 4) & 0xFF];
    return set1;
  }
  List<int> decodeEcgVals(int v1, int v2, int v3) {
    final d1 = ((v1 & 0xFF) | ((v2 & 0x0F) << 8)) - (2048);
    final d2 = (((v2 & 0xF0) >> 4) | ((v3 & 0xFF) << 4)) - (2048);
    return [d1, d2];
  }

    var res=true;
    var val1=0;
    var val2=0;
    var resval1=0;
    var resval2=0;
    while (res) {
          final data=encodeEcgVals(val1,val2);
          final decoded=decodeEcgVals(data[0],data[1],data[2]);
          resval1=decoded[0];
          resval2=decoded[1];
          res=val1 == resval1 && val2 == resval2;
          if(!res){
            print('$val1 => ${val1 == resval1}');
            print('$val2 => ${val2 == resval2}');
          }
          val1--;
          val2--;
    }

  // data.forEachIndexed((i,e){
  //   final l=e as List<dynamic>;
  //     for (var i = 0; i < l.length; i++) {
  //       if(i.isOdd && i>0){
  //         final l1=num.parse(l[i-1]['val'].toString()).toInt();
  //         final l2=num.parse(l[i]['val'].toString()).toInt();
  //         final data=encodeEcgVals(l1,l2);
  //         final decoded=decodeEcgVals(data[0],data[1],data[2]);
  //         print(
  //           "${[l1,l2]} => ${decoded[0] == l1 && decoded[1]==l2}"
  //         );
  //       }

  //     }
  // });

  

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
