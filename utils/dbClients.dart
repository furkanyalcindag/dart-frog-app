// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:async';

// import 'package:influxdb_client/api.dart';

// class DbInt {
//   factory DbInt() {
//     influxDBClient??= InfluxDBClient(
//       url: 'http://192.168.100.207:8086',
//       token: '26Xj0PqqEgmqnH9Cf1JGKVrYVADUhAZSrmTFADDhx71Wlo7AYdcPeikU-msurFlfw-WQ3ozajuevTmlvH8nc0Q==',
//       org: 'DK',
//       bucket: 'healtm',
//     );
//     return _dbint;
//   }

//   DbInt._internal();
//   static InfluxDBClient? influxDBClient;
//   static final DbInt _dbint = DbInt._internal();
//   Future<InfluxDBClient?> initilizeInflux()async {
//     await influxDBClient?.getReadyApi().getReady().then((e)  {
//       if(e.status == ReadyStatusEnum.ready){
//         print('influxDBClient initilized and connected!');
//         return influxDBClient;
//       }else{
//         print('influxDBClient does not initilized!');
//       }
//     });
//     return null;
//   }
// }


