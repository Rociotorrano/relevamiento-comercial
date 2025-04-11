import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

//ACA ESTA EL CODIGO PARA LA LOCALIZACION DEL CELULAR

Future<bool> handleLocationPermission(BuildContext context) async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return false;
  }
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Se niegan los permisos de ubicación')));
      return false;
    }
  }
  if (permission == LocationPermission.deniedForever) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Los permisos de ubicación se niegan permanentemente, no podemos solicitar permisos.')));
    return false;
  }
  return true;
}

Future<Position> getCurrentPosition() async {
  return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high)
      .then((Position position) {
    return position;
    // ignore: body_might_complete_normally_catch_error
  }).catchError((e) {
    debugPrint(e);
  });
}
