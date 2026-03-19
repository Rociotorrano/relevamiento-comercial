import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:relevamiento_comercial/servicios/globals.dart' as globals;
import 'package:relevamiento_comercial/servicios/guardar.dart';
import 'package:relevamiento_comercial/servicios/ubicacion.dart';

void main() => runApp(const PadronApp());

class PadronApp extends StatelessWidget {
  const PadronApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (context) => PadronData())],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF40A5DD),
          colorScheme: ColorScheme.fromSwatch().copyWith(
            secondary: const Color(0xFF40A5DD),
          ),
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

  bool _dropdownCalleOpen = false;
  bool _isSearchingCalle = false;
  TextEditingController _searchCalleController = TextEditingController();
  FocusNode _searchCalleFocus = FocusNode();
  List<Map<String, dynamic>> _callesFiltradas = [];

  Map<String, bool> camposValidos = {};

  List<Map<String, dynamic>> localidades = [];
  List<Map<String, dynamic>> calles = [];
  final List<File> _foto = [];
  List<Map<String, dynamic>> filtrarCalles = [];

  final TextEditingController padronController = TextEditingController();
  final TextEditingController cuitController = TextEditingController();
  final TextEditingController titularController = TextEditingController();
  final TextEditingController nom_fantasiaController = TextEditingController();
  final TextEditingController numeroController = TextEditingController();
  final TextEditingController numeroLocalController = TextEditingController();
  final TextEditingController rubroshabilotadosController =
      TextEditingController();
  final TextEditingController rubrosexplotadosController =
      TextEditingController();
  final TextEditingController publicidadController = TextEditingController();
  final TextEditingController observacionesController = TextEditingController();

  bool esValido = false;
  bool cuitValido = false;
  bool titularValido = false;
  bool nom_fantasiaValido = false;

  bool _padronBuscado = false;
  bool _padronExistente = false;
  bool _modoModificacion = false;

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

  Future<void> _cargarCalles(String fklocalidad) async {
    final nuevasCalles = await traerCalle(fklocalidad);
    setState(() {
      calles = nuevasCalles;
      selectedCalle = null;
    });
  }

  bool _validarFormulario() {
    bool formularioValido = true;
    Map<String, bool> validaciones = {};

    validaciones['nropadro'] = padronController.text.isNotEmpty;
    validaciones['cuit'] = cuitController.text.isNotEmpty;
    validaciones['titular'] = titularController.text.isNotEmpty;
    validaciones['nom_fantasia'] = nom_fantasiaController.text.isNotEmpty;
    validaciones['numero_calle'] =
        numeroController.text.isNotEmpty &&
        (camposValidos['numero_calle'] ?? true);
    validaciones['numero_local'] =
        numeroLocalController.text.isNotEmpty &&
        (camposValidos['numero_local'] ?? true);
    validaciones['rubros_habilitados'] =
        rubroshabilotadosController.text.isNotEmpty;
    validaciones['rubros_explota'] = rubrosexplotadosController.text.isNotEmpty;
    validaciones['elementos_publicidad'] = publicidadController.text.isNotEmpty;
    validaciones['observaciones'] = observacionesController.text.isNotEmpty;

    validaciones['localidad'] =
        selectedLocalidad != null &&
        selectedLocalidad!.isNotEmpty &&
        (camposValidos['localidad'] ?? true);
    validaciones['calle'] =
        selectedCalle != null &&
        selectedCalle!.isNotEmpty &&
        (camposValidos['calle'] ?? true);
    setState(() {
      camposValidos = validaciones;
    });

    formularioValido = !validaciones.containsValue(false);
    if (!formularioValido) {
      _mostrarMensajeGuardado(
        'Por favor, complete todos los campos obligatorios.',
      );
    }

    return formularioValido;
  }

  Future<void> _mostrarMensajeGuardado(String mensaje) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _confirmarSalida() async {
    bool salir =
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Cerrar sesión'),
              content: const Text(
                '¿Estás seguro de que querés cerrar la sesión?',
              ),
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
      setState(() {
        camposValidos['padron'] = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese un Nro. de Padrón válido')),
      );
      return;
    }

    var url = Uri.parse(
      'https://backend.sim.lacosta.gob.ar/recursos/traerDatosPadronFicha',
    );

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${globals.miTokenGlobal}',
        },
        body: jsonEncode({"nropadro": nropadro}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);

        Map<String, dynamic>? dataMap;
        bool existsInRelevamiento = false;

        if (result.containsKey('pkficha_relevamiento')) {
          dataMap = Map<String, dynamic>.from(result);
          existsInRelevamiento = true;
        } else if (result['datos'] is Map) {
          dataMap = Map<String, dynamic>.from(result['datos']);
          existsInRelevamiento = result['verificacion'] == true;
        } else if (result['datos'] is List && result['datos'].isNotEmpty) {
          dataMap = Map<String, dynamic>.from(result['datos'][0]);
          existsInRelevamiento = true;
        }

        if (dataMap != null && dataMap.isNotEmpty) {
          final map = dataMap;

          setState(() {
            cuitController.text = map['cuit']?.toString() ?? '';
            titularController.text = map['titular']?.toString() ?? '';
            nom_fantasiaController.text = map['nom_fantasia']?.toString() ?? '';

            numeroController.text = map['numero_calle']?.toString() ?? '';
            numeroLocalController.text = map['numero_local']?.toString() ?? '';

            rubroshabilotadosController.text =
                map['rubros_habilitados']?.toString() ?? '';

            rubrosexplotadosController.text =
                map['rubros_explota']?.toString() ?? '';

            publicidadController.text =
                map['elementos_publicidad']?.toString() ?? '';

            observacionesController.text =
                map['observaciones']?.toString() ?? '';

            final estadoVal =
                map['estado']?.toString().toUpperCase().trim() ?? '';

            selectedestadoAbiertoocerrado =
                (estadoVal == 'A' || estadoVal == 'ACTIVO')
                ? 'abierto'
                : 'Temporalmente cerrado';

            _certificadoHabilitacion =
                (map['certificado_habilitacion']?.toString() == '1');

            _comprobantesSegHigiene =
                (map['comprobantes_pago']?.toString() == '1');

            _servicioDelivery = (map['servicio_delivery']?.toString() == '1');

            _padronBuscado = true;
            _padronExistente = existsInRelevamiento;
            _modoModificacion = false;
            camposValidos['padron'] = true;
          });

          final String? fklocalidad = map['fklocalidad']?.toString();
          final String? fkcalle = map['fkcalle']?.toString();
          if (fklocalidad != null && fklocalidad.isNotEmpty) {
            await _cargarCalles(fklocalidad);

            setState(() {
              selectedLocalidad =
                  localidades.any(
                    (l) => l['pklocalidad'].toString() == fklocalidad,
                  )
                  ? fklocalidad
                  : null;

              camposValidos['localidad'] = selectedLocalidad != null;
            });

            if (fkcalle != null && fkcalle.isNotEmpty) {
              final existeCalle = calles.any(
                (c) => c['pkcalle'].toString() == fkcalle,
              );

              setState(() {
                selectedCalle = existeCalle ? fkcalle : null;
                camposValidos['calle'] = existeCalle;
              });
            }
          }

          if (existsInRelevamiento && mounted) {
            final modificar = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('Datos encontrados'),
                content: const Text('¿Desea modificar los datos?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('No, solo ver'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Sí, modificar'),
                  ),
                ],
              ),
            );

            if (modificar == true) {
              setState(() => _modoModificacion = true);
            }
          }
        } else {
          limpiarCampos();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'El padrón no existe en el sistema',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 3),
            ),
          );
          setState(() {
            _padronBuscado = false;
            _padronExistente = false;
            _modoModificacion = false;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error de conexión')));
    }
  }

  void limpiarCampos() {
    padronController.clear();
    cuitController.clear();
    titularController.clear();
    nom_fantasiaController.clear();
    numeroController.clear();
    numeroLocalController.clear();
    rubroshabilotadosController.clear();
    rubrosexplotadosController.clear();
    publicidadController.clear();
    observacionesController.clear();

    setState(() {
      selectedLocalidad = null;
      selectedCalle = null;
      calles = [];
      selectedestadoAbiertoocerrado = null;
      _certificadoHabilitacion = false;
      _comprobantesSegHigiene = false;
      _servicioDelivery = false;
      _foto.clear();
      _padronBuscado = false;
      _padronExistente = false;
      _modoModificacion = false;
      camposValidos.updateAll((key, value) => true);
    });
  }

  void _onpadronChanged(String value) {
    setState(() {
      cuitValido = false;
      titularValido = false;
      nom_fantasiaValido = false;
      _padronBuscado = false;
      _padronExistente = false;
      _modoModificacion = false;
      cuitController.clear();
      titularController.clear();
      nom_fantasiaController.clear();
      numeroController.clear();
      numeroLocalController.clear();
      rubroshabilotadosController.clear();
      rubrosexplotadosController.clear();
      publicidadController.clear();
      observacionesController.clear();
      selectedLocalidad = null;
      selectedCalle = null;
      calles = [];
      selectedestadoAbiertoocerrado = null;
      _certificadoHabilitacion = false;
      _comprobantesSegHigiene = false;
      _servicioDelivery = false;
    });
  }

  Future<void> guardarTodo() async {
    final uri = Uri.parse(
      'https://backend.sim.lacosta.gob.ar/recursos/guardarDatosFicha',
    );

    final request = http.MultipartRequest('POST', uri);
    final hasPermission = await handleLocationPermission(context);
    if (!hasPermission) {
      dialogAceptar(context, "No hay acceso a la ubicación.", 0);
      return;
    }

    Position? position = await getCurrentPosition();
    if (position == null) {
      dialogAceptar(context, "No se pudo obtener la ubicación GPS.", 0);
      return;
    }

    request.headers['Authorization'] = 'Bearer ${globals.miTokenGlobal}';

    request.fields['nropadro'] = padronController.text.trim();
    request.fields['cuit'] = cuitController.text.trim();
    request.fields['titular'] = titularController.text.trim();
    request.fields['nom_fantasia'] = nom_fantasiaController.text.trim();
    request.fields['fklocalidad'] = selectedLocalidad!;
    request.fields['fkcalle'] = selectedCalle!;
    request.fields['numero_calle'] = numeroController.text.trim();
    request.fields['numero_local'] = numeroLocalController.text.trim();
    request.fields['estado'] = selectedestadoAbiertoocerrado == "abierto"
        ? "A"
        : "CT";
    request.fields['certificado_habilitacion'] = _certificadoHabilitacion
        ? "SI"
        : "NO";
    request.fields['comprobantes_pago'] = _comprobantesSegHigiene ? "SI" : "NO";
    request.fields['servicio_delivery'] = _servicioDelivery ? "SI" : "NO";
    request.fields['rubros_habilitados'] = rubroshabilotadosController.text
        .trim();
    request.fields['rubros_explota'] = rubrosexplotadosController.text.trim();
    request.fields['elementos_publicidad'] = publicidadController.text.trim();
    request.fields['observaciones'] = observacionesController.text.trim();
    request.fields['longitud'] = position.longitude.toString();
    request.fields['latitud'] = position.latitude.toString();

    for (int i = 0; i < _foto.length; i++) {
      var archivo = _foto[i];
      if (archivo != null) {
        final stream = http.ByteStream(archivo.openRead());
        final length = await archivo.length();
        final multipartFile = http.MultipartFile(
          'archivo',
          stream,
          length,
          filename: archivo.path.split('/').last,
        );
        request.files.add(multipartFile);
      }
    }
    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      print('Respuesta del backend: $responseBody');

      print("Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        limpiarCampos();
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text(
                'Datos guardados correctamente',
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print("Error al guardar: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error de conexión')));
    }
  }

  bool _esReadOnly(TextEditingController controller) {
    if (!_padronBuscado) return true;
    if (!_padronExistente) return false;
    if (!_modoModificacion) return true;

    if (controller == cuitController) return true;
    if (controller == titularController) return true;
    if (controller == nom_fantasiaController) return true;
    return false;
  }

  bool _esEditable() {
    if (!_padronBuscado) return false;
    if (!_padronExistente) return true;
    return _modoModificacion;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        centerTitle: true,
        toolbarHeight: 120.0,
        elevation: 0,
        title: const Padding(
          padding: EdgeInsets.only(left: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Relevamiento',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF40A5DD),
                ),
              ),
              SizedBox(height: 10.0),
              Text(
                'Comercial',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF40A5DD),
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
            color: const Color(0xFF40A5DD),
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
              // Banner de estado
              if (_padronBuscado)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: !_padronExistente
                        ? const Color(0xFFE8F5E9)
                        : (_modoModificacion
                              ? const Color(0xFFFFF8E1)
                              : const Color(0xFFE3F2FD)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: !_padronExistente
                          ? Colors.green
                          : (_modoModificacion
                                ? Colors.orange
                                : const Color(0xFF40A5DD)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        !_padronExistente
                            ? Icons.fiber_new
                            : (_modoModificacion
                                  ? Icons.edit
                                  : Icons.visibility),
                        color: !_padronExistente
                            ? Colors.green
                            : (_modoModificacion
                                  ? Colors.orange
                                  : const Color(0xFF40A5DD)),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          !_padronExistente
                              ? 'Padrón nuevo — Complete todos los datos'
                              : (_modoModificacion
                                    ? 'Modo edición — CUIT, Titular y Nombre de Fantasía no son modificables'
                                    : 'Solo visualización'),
                          style: TextStyle(
                            fontSize: 13,
                            color: !_padronExistente
                                ? Colors.green[800]
                                : (_modoModificacion
                                      ? Colors.orange[800]
                                      : const Color(0xFF1565C0)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              _buildPadron(padronController),
              _buildTexto('Cuit:', cuitController, isNumeric: true),
              _buildTexto('Titular:', titularController),
              _buildTexto('Nombre de Fantasía:', nom_fantasiaController),
              const Divider(color: Color(0xFF40A5DD), thickness: 2),
              _buildDropdownLocalidad(),
              const Divider(color: Color(0xFF40A5DD), thickness: 2),
              _buildDropdownCalle(),
              const Divider(color: Color(0xFF40A5DD), thickness: 2),
              _buildFilaNumeroYNumeroLocal(),
              const Divider(color: Color(0xFF40A5DD), thickness: 2),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RadioListTile<String>(
                    title: const Text('Abierto'),
                    value: 'abierto',
                    groupValue: selectedestadoAbiertoocerrado,
                    onChanged: _esEditable()
                        ? (value) => setState(
                            () => selectedestadoAbiertoocerrado = value,
                          )
                        : null,
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<String>(
                    title: const Text('Temporalmente cerrado'),
                    value: 'Temporalmente cerrado',
                    groupValue: selectedestadoAbiertoocerrado,
                    onChanged: _esEditable()
                        ? (value) => setState(
                            () => selectedestadoAbiertoocerrado = value,
                          )
                        : null,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
              const Divider(color: Color(0xFF40A5DD), thickness: 2),
              const SizedBox(height: 25),
              CheckboxListTile(
                title: const Text('Certificado de habilitación'),
                value: _certificadoHabilitacion,
                onChanged: _esEditable()
                    ? (bool? v) =>
                          setState(() => _certificadoHabilitacion = v ?? false)
                    : null,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Comprobantes de pago de Seg e Higiene'),
                value: _comprobantesSegHigiene,
                onChanged: _esEditable()
                    ? (bool? v) =>
                          setState(() => _comprobantesSegHigiene = v ?? false)
                    : null,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Servicio de delivery'),
                value: _servicioDelivery,
                onChanged: _esEditable()
                    ? (bool? v) =>
                          setState(() => _servicioDelivery = v ?? false)
                    : null,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(color: Color(0xFF40A5DD), thickness: 2),
              _buildTexto(
                'Rubros Habilitados:',
                rubroshabilotadosController,
                maxLines: 6,
              ),
              _buildTexto(
                'Rubros Explotados:',
                rubrosexplotadosController,
                maxLines: 6,
              ),
              _buildTexto(
                'Elementos de publicidad o de ocupación en la vía pública:',
                publicidadController,
                maxLines: 6,
              ),
              _buildTexto(
                'Observaciones:',
                observacionesController,
                maxLines: 6,
              ),
              const SizedBox(height: 8),
              _buildFotos(),
              const SizedBox(height: 10),
              if (_modoModificacion || (_padronBuscado && !_padronExistente))
                Center(
                  child: ElevatedButton(
                    onPressed: guardarTodo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF40A5DD),
                      padding: const EdgeInsets.symmetric(
                        vertical: 15.0,
                        horizontal: 40.0,
                      ),
                      minimumSize: const Size(150, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> validarLocalidad() async {
    if (selectedLocalidad == null || selectedLocalidad!.isEmpty) {
      setState(() {
        camposValidos['localidad'] = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione una Localidad válida')),
      );
      return;
    }
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
            color: _esEditable() ? null : Colors.grey[100],
            border: Border.all(
              color: esValido ? Colors.grey : Colors.red,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: DropdownButton<String>(
            hint: const Text('Selecciona una localidad'),
            value:
                localidades.any(
                  (l) => l['pklocalidad'].toString() == selectedLocalidad,
                )
                ? selectedLocalidad
                : null,
            isExpanded: true,
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            dropdownColor: Colors.white,
            items: localidades.map<DropdownMenuItem<String>>((localidad) {
              return DropdownMenuItem<String>(
                value: localidad['pklocalidad'].toString(),
                child: Text(localidad['localidad'] ?? 'No disponible'),
              );
            }).toList(),
            onChanged: _esEditable()
                ? (String? value) async {
                    if (value != null && value.isNotEmpty) {
                      setState(() {
                        selectedLocalidad = value;
                        camposValidos['localidad'] = true;
                      });
                      await _cargarCalles(value);
                    } else {
                      setState(() {
                        selectedLocalidad = null;
                        calles = [];

                        camposValidos['localidad'] = false;
                      });
                    }
                  }
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownCalle() {
    bool esValido = camposValidos['calle'] ?? true;
    String displayText = '';

    if (selectedCalle != null) {
      final existe = calles.any(
        (c) => c['pkcalle'].toString() == selectedCalle,
      );

      if (existe) {
        displayText =
            calles.firstWhere(
              (c) => c['pkcalle'].toString() == selectedCalle,
            )['calle'] ??
            '';
      }
    }
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
        AbsorbPointer(
          absorbing: !_esEditable(),
          child: Container(
            decoration: BoxDecoration(
              color: _esEditable() ? null : Colors.grey[100],
              border: Border.all(color: esValido ? Colors.grey : Colors.red),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: !_esEditable()
                      ? null
                      : () {
                          setState(() {
                            _dropdownCalleOpen = !_dropdownCalleOpen;
                            if (_dropdownCalleOpen) {
                              _callesFiltradas = List.from(calles);
                              _searchCalleController.clear();
                              FocusScope.of(
                                context,
                              ).requestFocus(_searchCalleFocus);
                            }
                          });
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _dropdownCalleOpen
                              ? TextField(
                                  focusNode: _searchCalleFocus,
                                  controller: _searchCalleController,
                                  decoration: const InputDecoration(
                                    hintText: 'Buscar calle...',
                                    isDense: true,
                                    border: InputBorder.none,
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      if (value.isEmpty) {
                                        _callesFiltradas = calles;
                                      } else {
                                        _callesFiltradas = calles
                                            .where(
                                              (calle) => calle['calle']
                                                  .toLowerCase()
                                                  .contains(
                                                    value.toLowerCase(),
                                                  ),
                                            )
                                            .toList();
                                      }
                                    });
                                  },
                                )
                              : Text(
                                  displayText.isEmpty
                                      ? 'Seleccione una calle'
                                      : displayText,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: displayText.isEmpty
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                        ),
                        if (selectedCalle != null && !_dropdownCalleOpen)
                          IconButton(
                            icon: const Icon(Icons.clear, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                selectedCalle = null;
                                camposValidos['calle'] = false;
                              });
                            },
                            tooltip: 'Borrar selección',
                          ),
                      ],
                    ),
                  ),
                ),
                if (_dropdownCalleOpen)
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.black)),
                    ),
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _callesFiltradas.length,
                      itemBuilder: (context, index) {
                        final calle = _callesFiltradas[index];
                        return ListTile(
                          title: Text(
                            calle['calle'] ?? 'No disponible',
                            style: const TextStyle(fontSize: 16),
                          ),
                          onTap: () {
                            setState(() {
                              selectedCalle = calle['pkcalle'].toString();
                              camposValidos['calle'] = true;
                              _dropdownCalleOpen = false;
                              _searchCalleController.clear();
                            });
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ), // cierre Container
        ), // cierre AbsorbPointer
        if (!esValido && calles.isNotEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Text(
              "*Debe seleccionar una calle",
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
            'Nro. Padrón:',
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
            onChanged: _onpadronChanged,
            decoration: InputDecoration(
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: datosPadron,
              ),
              errorText: !esValido ? "*requerido" : null,
              errorStyle: const TextStyle(color: Colors.red),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: esValido
                      ? const Color.fromARGB(255, 128, 122, 122)
                      : Colors.red,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF40A5DD),
                  width: 2.0,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilaNumeroYNumeroLocal() {
    return Row(
      children: [
        Expanded(
          child: _buildTexto('Número:', numeroController, isNumeric: true),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildTexto(
            'Número Local:',
            numeroLocalController,
            isNumeric: true,
          ),
        ),
      ],
    );
  }

  Widget _buildTexto(
    String label,
    TextEditingController controller, {
    bool isNumeric = false,
    int maxLines = 1,
    bool showSearchIcon = false,
  }) {
    String campoKey = '';

    if (controller == cuitController) campoKey = 'cuit';
    if (controller == titularController) campoKey = 'titular';
    if (controller == nom_fantasiaController) campoKey = 'nom_fantasia';
    if (controller == numeroController) campoKey = 'numero_calle';
    if (controller == numeroLocalController) campoKey = 'numero_local';
    if (controller == rubroshabilotadosController)
      campoKey = 'rubros_habilitados';
    if (controller == rubrosexplotadosController) campoKey = 'rubros_explota';
    if (controller == publicidadController) campoKey = 'elementos_publicidad';
    if (controller == observacionesController) campoKey = 'observaciones';

    bool esValido = camposValidos[campoKey] ?? true;
    bool readOnly = _esReadOnly(controller);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            readOnly: readOnly,
            keyboardType: isNumeric
                ? TextInputType.number
                : TextInputType.multiline,
            maxLines: maxLines,
            decoration: InputDecoration(
              filled: readOnly,
              fillColor: readOnly ? Colors.grey[100] : null,
              errorText: !esValido ? "*requerido" : null,
              errorStyle: const TextStyle(color: Colors.red),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: readOnly
                      ? Colors.grey.shade300
                      : (esValido ? Colors.grey : Colors.red),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: esValido ? const Color(0xFF40A5DD) : Colors.red,
                  width: 2.0,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
