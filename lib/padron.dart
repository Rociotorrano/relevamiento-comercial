import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:relevamientocomercial/servicios/globals.dart' as globals;
import 'package:relevamientocomercial/servicios/guardar.dart';

void main() => runApp(const PadronApp());

class PadronApp extends StatelessWidget {
  const PadronApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => PadronData()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF40A5DD),
          colorScheme: ColorScheme.fromSwatch()
              .copyWith(secondary: const Color(0xFF40A5DD)),
        ),
        home: const PadronPage(),
      ),
    );
  }
}

class PadronData with ChangeNotifier {}

class PadronPage extends StatefulWidget {
  const PadronPage({super.key});

  @override
  _PadronPageState createState() => _PadronPageState();
}

class _PadronPageState extends State<PadronPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String? selectedLocalidad;
  String? selectedCalle;
  String? selectedestadoAbiertoocerrado;
  bool _certificadoHabilitacion = false;
  bool _comprobantesSegHigiene = false;
  bool _servicioDelivery = false;
  bool _camposHabilitados = true;
  List<Map<String, dynamic>> localidades = [];
  List<Map<String, dynamic>> calles = [];
  final List<File> _foto = [];

  final TextEditingController padronController = TextEditingController();
  final TextEditingController cuitController = TextEditingController();
  final TextEditingController titularController = TextEditingController();
  final TextEditingController nombrefantasiaController =
      TextEditingController();
  final TextEditingController numeroController = TextEditingController();
  final TextEditingController numeroLocalController = TextEditingController();
  final TextEditingController rubroshabilotadosController =
      TextEditingController();
  final TextEditingController rubrosexplotadosController =
      TextEditingController();
  final TextEditingController publicidadController = TextEditingController();
  final TextEditingController observacionesController = TextEditingController();

  bool padronValido = false;
  bool esValido = false;
  bool cuitValido = false;
  bool titularValido = false;
  bool nom_fantasiaValido = false;

  Map<String, bool> camposValidos = {
    'nropadro': true,
    'cuit': true,
    'titular': true,
    'nombrefantasia': true,
    'localidad': true,
    'calle': true,
    'numero_calle': true,
    'numero_local': true,
    'estado': true,
    'certificado_habilitacion': true,
    'comprobantes_pago': true,
    'servicio_delivery': true,
    'rubros_habilitados': true,
    'rubros_explota': true,
    'elementos_publicidad': true,
    'observaciones': true,
  };

  @override
  void initState() {
    super.initState();
    _cargarLocalidades();
  }

  Future<void> _cargarLocalidades() async {
    localidades = await traerLocalidad('');
    localidades.forEach((localidad) => print(localidad));
    setState(() {});
  }

  Future<void> _cargarCalles(String localidad) async {
    calles = await traerCalle(localidad);
    setState(() {
      selectedCalle = null;
    });
  }

  bool _validarFormulario() {
    bool formularioValido = true;

    Map<String, bool> validaciones = Map.from(camposValidos);

    validaciones['nropadro'] = padronController.text.isNotEmpty;
    validaciones['cuit'] = cuitController.text.isNotEmpty;
    validaciones['titular'] = titularController.text.isNotEmpty;
    validaciones['nombrefantasia'] = nombrefantasiaController.text.isNotEmpty;

    validaciones['localidad'] = selectedLocalidad != null;
    validaciones['calle'] = selectedCalle != null;
    validaciones['numero_calle'] = numeroController.text.isNotEmpty;
    validaciones['numero_local'] = numeroLocalController.text.isNotEmpty;
    validaciones['estado'] = selectedestadoAbiertoocerrado != null;
    validaciones['certificado_habilitacion'] =
        selectedestadoAbiertoocerrado != null;
    validaciones['comprobantes_pago'] = selectedestadoAbiertoocerrado != null;
    validaciones['servicio_delivery'] = selectedestadoAbiertoocerrado != null;

    validaciones['rubros_habilitados'] =
        rubroshabilotadosController.text.isNotEmpty;
    validaciones['rubros_explota'] = rubrosexplotadosController.text.isNotEmpty;
    validaciones['elementos_publicidad('] =
        publicidadController.text.isNotEmpty;
    validaciones['observaciones'] = observacionesController.text.isNotEmpty;

    if (validaciones.containsValue(false)) {
      formularioValido = false;
      _mostrarMensajeGuardado(
          'Por favor, complete todos los campos obligatorios.');
    }

    setState(() {
      camposValidos = validaciones;
    });

    return formularioValido;
  }

  Future<void> _mostrarMensajeGuardado(String mensaje) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _confirmarSalida() async {
    bool salir = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Cerrar sesión'),
              content:
                  const Text('¿Estás seguro de que querés cerrar la sesión?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => exit(0),
                  child: const Text('Salir'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (salir) {
      exit(0);
    }
  }

  Future<void> _sacarFoto() async {
    try {
      final ImagePicker _picker = ImagePicker();
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);

      if (image != null) {
        setState(() {
          _foto.add(File(image.path));
        });
      }
    } catch (e) {
      _mostrarMensajeGuardado('Error al capturar la foto: $e');
    }
  }

  Widget _buildFotos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'FOTOS',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemCount: _foto.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    backgroundColor: Colors.black,
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              _foto[index],
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _foto[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _foto.removeAt(index);
                        });
                      },
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        IconButton(
          onPressed: _sacarFoto,
          icon: const Icon(Icons.camera_alt, color: Colors.blue),
          iconSize: 30,
        ),
      ],
    );
  }

  Future<void> datosPadron() async {
    String nropadro = padronController.text.trim();

    if (nropadro.isEmpty || int.tryParse(nropadro) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ingrese un Nro. de Padrón válido')),
      );
      return;
    }

    var url =
        Uri.parse('http://11.11.15.20:5019/recursos/traerDatosPadronFicha');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${globals.miTokenGlobal}',
        },
        body: jsonEncode({"nropadro": nropadro}),
      );

      print(response.statusCode);
      print("BODY RAW: '${response.body}'");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result is List && result.isNotEmpty) {
          final datos = result[0];
          setState(() {
            cuitController.text = datos['cuit'] ?? '';
            titularController.text = datos['titular'] ?? '';
            nombrefantasiaController.text = datos['nom_fantasia']?.trim() ?? '';
            _camposHabilitados = false;
          });
        } else {
          limpiarCampos();
          setState(() {
            _camposHabilitados = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('No se encontraron datos, ingrese número de Padron')),
          );
        }
      } else {
        // Mostrar error si la respuesta del servidor no es exitosa
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error del servidor: ${response.statusCode}')),
        );
      }
    } catch (e) {
      // Manejo de error de conexión
      print('Ocurrió un error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión')),
      );
    }
  }

  void limpiarCampos() {
    cuitController.clear();
    titularController.clear();
    nombrefantasiaController.clear();
  }

  void _onpadronChanged(String value) {
    setState(() {
      padronValido = value.trim().isNotEmpty;
      cuitValido = false;
      titularValido = false;
      nom_fantasiaValido = false;
    });
  }

  Future<void> guardarTodo() async {
    // Armamos el JSON con los valores actuales
    final Map<String, dynamic> datosFicha = {
      "nropadro": padronController.text.trim(),
      "cuit": cuitController.text.trim(),
      "titular": titularController.text.trim(),
      "nom_fantasia": nombrefantasiaController.text.trim(),
      "localidad": selectedLocalidad ?? "",
      "calle": selectedCalle ?? "",
      "numero_calle": numeroController.text.trim(),
      "numero_local": numeroLocalController.text.trim(),
      "estado": selectedestadoAbiertoocerrado == "abierto" ? "A" : "CT",
      "certificado_habilitacion": _certificadoHabilitacion ? "SI" : "NO",
      "comprobantes_pago": _comprobantesSegHigiene ? "SI" : "NO",
      "servicio_delivery": _servicioDelivery ? "SI" : "NO",
      "rubros_habilitados": rubroshabilotadosController.text.trim(),
      "rubros_explota": rubrosexplotadosController.text.trim(),
      "elementos_publicidad": publicidadController.text.trim(),
      "observaciones": observacionesController.text.trim(),
    };

    List<String> fotosBase64 = [];
    for (var _foto in _foto) {
      if (_foto != null) {
        final bytes = await _foto.readAsBytes();
        String base64Image = base64Encode(bytes);
        fotosBase64.add(base64Image);
      }
    }

    // Agregamos las fotos al JSON
    if (fotosBase64.isNotEmpty) {
      datosFicha['fotos'] = fotosBase64;
    }

    var url = Uri.parse('http://11.11.15.20:5019/recursos/guardarDatosFicha');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${globals.miTokenGlobal}',
        },
        body: jsonEncode(datosFicha),
      );

      print("Status: ${response.statusCode}");
      print("Body: ${response.body}");

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Datos guardados correctamente')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print("Error al guardar: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF40A5DD),
        centerTitle: true,
        toolbarHeight: 120.0,
        elevation: 0,
        title: const Padding(
          padding: EdgeInsets.only(left: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Relevamiento Comercial',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _confirmarSalida,
            tooltip: 'Cerrar sesión',
            color: Colors.white,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildPadron(padronController),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child:
                        _buildTexto('Cuit:', cuitController, isNumeric: true),
                  ),
                ],
              ),
              _buildTexto('Titular:', titularController),
              _buildTexto('Nombre de Fantasía:', nombrefantasiaController),
              const Divider(color: Color(0xFF40A5DD), thickness: 2),
              _buildDropdownLocalidad(),
              const Divider(color: Color(0xFF40A5DD), thickness: 2),
              _buildDropdownCalle(),
              const Divider(color: Color(0xFF40A5DD), thickness: 2),
              Row(
                children: [
                  Expanded(
                    child: _buildTexto('Número:', numeroController,
                        isNumeric: true),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTexto('Nro. Local:', numeroLocalController,
                        isNumeric: true),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Abierto'),
                      value: 'abierto',
                      groupValue: selectedestadoAbiertoocerrado,
                      onChanged: (value) {
                        setState(() {
                          selectedestadoAbiertoocerrado = value;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Temporalmente cerrado'),
                      value: 'Temporalmente cerrado',
                      groupValue: selectedestadoAbiertoocerrado,
                      onChanged: (value) {
                        setState(() {
                          selectedestadoAbiertoocerrado = value;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              CheckboxListTile(
                title: const Text('Certificado de habilitación'),
                value: _certificadoHabilitacion,
                onChanged: (bool? value) {
                  setState(() {
                    _certificadoHabilitacion = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Comprobantes de pago de Seg e Higiene'),
                value: _comprobantesSegHigiene,
                onChanged: (bool? value) {
                  setState(() {
                    _comprobantesSegHigiene = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Servicio de delivery'),
                value: _servicioDelivery,
                onChanged: (bool? value) {
                  setState(() {
                    _servicioDelivery = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              _buildTexto('Rubros Habilitados:', rubroshabilotadosController,
                  maxLines: 6),
              _buildTexto('Rubros Explotados:', rubrosexplotadosController,
                  maxLines: 6),
              _buildTexto(
                  'Elementos de publicidad o de ocupación en la vía pública:',
                  publicidadController,
                  maxLines: 6),
              _buildTexto('Observaciones:', observacionesController,
                  maxLines: 6),
              const SizedBox(height: 30),
              _buildFotos(),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: guardarTodo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF40A5DD),
                    padding: const EdgeInsets.symmetric(
                        vertical: 15.0, horizontal: 40.0),
                    minimumSize: Size(150, 50),
                  ),
                  child: const Text(
                    'GUARDAR',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownLocalidad() {
    bool esValido = camposValidos['localidad'] ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Localidad:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey, width: 1.0),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: DropdownButton<String>(
            hint: const Text('Selecciona una localidad'),
            value: selectedLocalidad,
            isExpanded: true,
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            dropdownColor: Colors.white,
            items: localidades.map<DropdownMenuItem<String>>((localidad) {
              return DropdownMenuItem<String>(
                value: localidad['pklocalidad'].toString(),
                child: Text(localidad['localidad'] ?? 'No disponible'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedLocalidad = value;
                calles = [];
                camposValidos['localidad'] = true;
              });
              _cargarCalles(value!);
            },
          ),
        ),
        if (!esValido)
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Text(
              "*requerido",
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildDropdownCalle() {
    bool esValido = camposValidos['calle'] ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Calle:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey, width: 1.0),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: DropdownButton<String>(
            hint: const Text('Selecciona una calle'),
            value: selectedCalle,
            isExpanded: true,
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            dropdownColor: Colors.white,
            items: calles.map<DropdownMenuItem<String>>((calle) {
              return DropdownMenuItem<String>(
                value: calle['pkcalle'].toString(),
                child: Text(calle['calle'] ?? 'No disponible'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedCalle = value;
                camposValidos['calle'] = true;
              });
            },
          ),
        ),
        if (!esValido)
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Text(
              "*requerido",
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildPadron(TextEditingController controller) {
    bool esValido = camposValidos['padron'] ?? true;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nro. de Padrón:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: datosPadron,
              ),
              errorText: !esValido ? "*requerido" : null,
              errorStyle: const TextStyle(color: Colors.red),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: esValido
                      ? const Color.fromARGB(255, 128, 122, 122)
                      : Colors.red,
                  width: 1.5,
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF40A5DD), width: 2.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTexto(String label, TextEditingController controller,
      {bool isNumeric = false, int maxLines = 1, bool showSearchIcon = false}) {
    String campoKey = '';

    if (controller == cuitController) campoKey = 'cuit';
    if (controller == titularController) campoKey = 'titular';
    if (controller == nombrefantasiaController) campoKey = 'nombrefantasia';
    if (controller == numeroController) campoKey = 'numero_calle';
    if (controller == numeroLocalController) campoKey = 'numero_local';
    if (controller == rubroshabilotadosController)
      campoKey = 'rubros_habilitados';
    if (controller == rubrosexplotadosController) campoKey = 'rubros_explota';
    if (controller == publicidadController) campoKey = 'elementos_publicidad';
    if (controller == observacionesController) campoKey = 'observaciones';

    bool esValido = camposValidos[campoKey] ?? true;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType:
              isNumeric ? TextInputType.number : TextInputType.multiline,
          maxLines: maxLines,
          decoration: InputDecoration(
            errorText: !esValido ? "*requerido" : null,
            errorStyle: const TextStyle(color: Colors.red),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color:
                    esValido ? Color.fromARGB(255, 128, 122, 122) : Colors.red,
                width: 1.5,
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
