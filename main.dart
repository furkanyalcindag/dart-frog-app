import 'dart:async';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'utils/dbClients.dart';

Future<HttpServer> run(Handler handler, InternetAddress ip, int port) async {
  return serve(handler, ip, port, poweredByHeader: 'Powered by Mskayali');
}
