import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:relevamientocomercial/servicios/guardar.dart';

void main() => runApp(const PadronApp());

class PadronApp extends StatelessWidget {
  const PadronApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => PadronData()),
        // Provider(create: (context) => DataCubit()),
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
  List<Map<String, dynamic>> localidades = [];
  List<Map<String, dynamic>> calles = [];

  final TextEditingController _padronController = TextEditingController();
  final TextEditingController _cuitController = TextEditingController();
  final TextEditingController _nombrefantasiaController =
      TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _numeroLocalController = TextEditingController();

  Map<String, bool> _camposValidos = {
    'Nro. Padrón': true,
    'cuit': true,
    'nombre fantasia': true,
    'numero': true,
    'numeroLocal': true,
    'localidad': true,
    'calle': true,
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

    Map<String, bool> validaciones = Map.from(_camposValidos);

    // Validar cada campo
    validaciones['Nro. Padrón'] = _padronController.text.isNotEmpty;
    validaciones['cuit'] = _cuitController.text.isNotEmpty;
    validaciones['nombre de fantasia'] =
        _nombrefantasiaController.text.isNotEmpty;
    validaciones['numero'] = _numeroController.text.isNotEmpty;
    validaciones['numeroLocal'] = _numeroLocalController.text.isNotEmpty;

    validaciones['localidad'] = selectedLocalidad != null;
    validaciones['calle'] = selectedCalle != null;

    // Verificar si algún campo no es válido
    if (validaciones.containsValue(false)) {
      formularioValido = false;
      _mostrarMensajeGuardado(
          'Por favor, complete todos los campos obligatorios.');
    }

    // Actualizar el estado para reflejar los campos inválidos
    setState(() {
      _camposValidos = validaciones;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF40A5DD),
        centerTitle: true,
        toolbarHeight: 90.0,
        elevation: 0,
        title: const Padding(
          padding: EdgeInsets.only(left: 20.0),
          // child: Text(
          //   'DATOS',
          //   style: TextStyle(
          //     fontSize: 35,
          //     fontWeight: FontWeight.bold,
          //     color: Colors.white,
          //   ),
          // ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildTexto('Nro. Padrón:', _padronController,
                    isNumeric: true),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTexto('Cuit:', _cuitController),
              ),
            ],
          ),
          _buildTexto('Nombre de Fantasía:', _nombrefantasiaController),
          const Divider(color: Color(0xFF40A5DD), thickness: 2),
          _buildDropdownLocalidad(),
          const Divider(color: Color(0xFF40A5DD), thickness: 2),
          _buildDropdownCalle(),
          const Divider(color: Color(0xFF40A5DD), thickness: 2),
          _buildTexto('N°:', _numeroController, isNumeric: true),
          _buildTexto('N° Local:', _numeroLocalController, isNumeric: true),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDropdownLocalidad() {
    bool esValido = _camposValidos['localidad'] ?? true;

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
                _camposValidos['localidad'] = true;
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
    bool esValido = _camposValidos['calle'] ?? true;

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
            items: calles.map<DropdownMenuItem<String>>((calle) {
              return DropdownMenuItem<String>(
                value: calle['pkcalle'].toString(),
                child: Text(calle['calle'] ?? 'No disponible'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedCalle = value;
                _camposValidos['calle'] = true;
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

  Widget _buildTexto(String label, TextEditingController controller,
      {bool isNumeric = false}) {
    String campoKey = '';
    if (controller == _padronController) campoKey = 'Nro. Padrón';
    if (controller == _cuitController) campoKey = 'cuit';
    if (controller == _numeroController) campoKey = 'numero';
    if (controller == _numeroLocalController) campoKey = 'numeroLocal';

    bool esValido = _camposValidos[campoKey] ?? true;

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
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              errorText: !esValido ? "*requerido" : null,
              errorStyle: const TextStyle(color: Colors.red),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: esValido
                      ? Color.fromARGB(255, 128, 122, 122)
                      : Colors.red,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: esValido ? const Color(0xFF40A5DD) : Colors.red,
                  width: 1.5,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            ),
            onChanged: (value) {
              if (!esValido) {
                setState(() {
                  _camposValidos[campoKey] = true;
                });
              }
            },
          ),
        ],
      ),
    );
  }
}
