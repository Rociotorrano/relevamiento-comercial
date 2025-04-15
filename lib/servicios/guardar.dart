//?LOGIN

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:relevamientocomercial/main.dart';
import 'package:relevamientocomercial/padron.dart';
import 'package:relevamientocomercial/servicios/globals.dart';
import 'package:relevamientocomercial/servicios/ubicacion.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'globals.dart' as globals;

Future<List<LoginApp>?> login(
    BuildContext context, String usuario, String password, int pasar) async {
  var url = Uri.parse('https://backend.sim.lacosta.gob.ar/loguear');

// http://11.11.15.8:4011/login//
  final hasPermission = await handleLocationPermission(context);
  if (!hasPermission) {
    dialogAceptar(context,
        "No hay acceso a la ubicación por favor habilite los servicios", 0);

    return null;
  }

  try {
    var response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer ${globals.miTokenGlobal}',
      },
      body: jsonEncode({"usuario": usuario, "password": password}),
    );

    if (response.statusCode == 200) {
      print('Datos enviados exitosamente.');
      final data = jsonDecode(response.body);
      if (data['estado']) {
        miTokenGlobal = data['token']; // Asignar valor a la variable global
        var loginData = Provider.of<LoginData>(context, listen: false);
        loginData.setToken(data['token']);

        if (pasar == 1)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PadronApp()),
          );
        return null;
      } else {
        print('La respuesta es incorrecta.');
        dialogAceptar(context, data['error'], 0);
        return null;
      }
    } else {
      print('Falló con status: ${response.statusCode}');
      print('Razón: ${response.reasonPhrase}');
      print('Cuerpo de respuesta: ${response.body}');

      return null;
    }
  } catch (error) {
    print('Error al intentar iniciar sesión: $error');
    dialogAceptar(context, 'Ocurrio un error, intente nuevamente.', 0);
    return null;
  }
}

//?LIMPIAR PREFERENCIAS
Future<void> limpiarPreferencias(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final keys = prefs.getKeys();
  for (var key in keys) {
    if (key.startsWith('vehiculo')) {
      prefs.remove(key);
    }
  }
}

//? ACEPTAR DE MENSAJE
Future<void> _mostrarMensajeGuardar(
    BuildContext context, String mensaje, int siguiente) async {
  BuildContext? validContext = context;
  showDialog(
    context: validContext,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Guardado con Éxito',
            style: TextStyle(color: Colors.black)),
        content: Text(mensaje, style: TextStyle(color: Colors.black)),
        actions: [
          TextButton(
            onPressed: () {
              if (siguiente == 1) {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              } else if (siguiente == 2) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const PadronApp()),
                );
              } else if (siguiente == 0) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Aceptar',
                style: TextStyle(color: Colors.black)), // Cambio para el botón
          ),
        ],
      );
    },
  );
}

//? ACEPTAR
Future<void> dialogAceptar(
    BuildContext context, String texto, int pasar) async {
  BuildContext? validContext = context;
  showDialog(
    context: validContext,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        content: Text(texto),
        actions: [
          TextButton(
            onPressed: () {
              if (pasar == 1) {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              } else if (pasar == 2) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const PadronApp()),
                );
              } else if (pasar == 0) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Aceptar'),
          ),
        ],
      );
    },
  );
}

//? TRAER LOCALIDADES
Future<List<Map<String, dynamic>>> traerLocalidad(localidades) async {
  var url =
      Uri.parse('https://backend.sim.lacosta.gob.ar/generales/localidades');

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer ${globals.miTokenGlobal}',
      },
      body: jsonEncode({"localidades": localidades}),
    );

    if (response.statusCode == 200) {
      final dynamic jsonBody = json.decode(response.body);

      if (jsonBody is Map &&
          jsonBody.containsKey('data') &&
          jsonBody['data'] is List) {
        return List<Map<String, dynamic>>.from(jsonBody['data']);
      } else if (jsonBody is List) {
        return List<Map<String, dynamic>>.from(jsonBody);
      } else {
        throw Exception('Formato de respuesta inesperado.');
      }
    } else {
      throw Exception('Error en la solicitud: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error al obtener localidades: $e');
  }
}

//? TRAER CALLES
Future<List<Map<String, dynamic>>> traerCalle(fklocalidad) async {
  var url = Uri.parse('https://backend.sim.lacosta.gob.ar/generales/calles');

  try {
    final response = await http.post(
      url,
      body: jsonEncode({"fklocalidad": fklocalidad}),
    );

    if (response.statusCode == 200) {
      final dynamic jsonBody = json.decode(response.body);

      if (jsonBody is Map &&
          jsonBody.containsKey('data') &&
          jsonBody['data'] is List) {
        return List<Map<String, dynamic>>.from(jsonBody['data']);
      } else if (jsonBody is List) {
        return List<Map<String, dynamic>>.from(jsonBody);
      } else {
        throw Exception('Formato de respuesta inesperado.');
      }
    } else {
      throw Exception('Error en la solicitud: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error al obtener calles: $e');
  }
}
