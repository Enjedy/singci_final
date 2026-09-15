import 'package:connectivity_plus/connectivity_plus.dart';

Future<bool> hasInternet() async {
  var result = await Connectivity().checkConnectivity();
  return !result.contains(ConnectivityResult.none);
}