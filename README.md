# generar iconos





#### 1. Proceso de Login (`LoginPage`en `main.dart`y funciones en `guardar.dart`)

El proceso de inicio de sesión es el primer paso para acceder a la funcionalidad principal de la aplicación:

- **Interfaz de Usuario:** `LoginPage` presenta campos de texto para "USUARIO" y "CONTRASEÑA", un botón "INGRESAR" y un logo. La visibilidad de la contraseña se puede alternar.
- **Inicio de Sesión (`iniciarSesion`):**

1. **Captura de Credenciales:** Obtiene el nombre de usuario y la contraseña ingresados por el usuario.
2. **Gestión de Estado:** Utiliza `Provider` para actualizar el `LoginData` con las credenciales ingresadas.
3. **Llamada a la Función `login`:** Invoca la función `login` (definida en `guardar.dart`) para manejar la lógica de autenticación.

- **Función `login` (en `guardar.dart`):**

1. **Verificación de Permisos de Ubicación:** Antes de intentar el login, llama a `handleLocationPermission` (de `ubicacion.dart`) para asegurarse de que la aplicación tiene acceso a los servicios de ubicación.
Si los permisos son denegados o los servicios de ubicación no están habilitados, muestra un `dialogAceptar` informando al usuario y detiene el proceso de login.


#### 2. Formulario Principal de Relevamiento (`PadronPage`en `padron.dart`)

Esta es la pantalla central donde se realiza el relevamiento de un comercio:

- **Carga Inicial:** Al iniciar `PadronPage`, se llama a `_cargarLocalidades()` para obtener la lista de localidades disponibles desde la API (`traerLocalidad` en `guardar.dart`).
- **Campos de Entrada de Datos:**
- **Nro. Padrón:** Campo principal para identificar el comercio. Incluye un icono de búsqueda que, al ser presionado, llama a `datosPadron()`.
- **`datosPadron()`:** Valida el número de padrón. Si es válido, realiza una petición `POST` a `https://backend.sim.lacosta.gob.ar/recursos/traerDatosPadronFicha` para obtener información existente del padrón. Si se encuentran datos, autocompleta los campos de CUIT, Titular y Nombre de Fantasía. Si no se encuentra información, muestra un `SnackBar`.


- **CUIT, Titular, Nombre de Fantasía:** Campos de texto para la información básica del comercio.
- **Localidad:** Un `DropdownButton` que muestra las localidades cargadas. Al seleccionar una localidad, se llama a `_cargarCalles()` para poblar el siguiente dropdown.
- **Calle:** Un campo de texto con funcionalidad de búsqueda y un `Dropdown` que muestra las calles de la localidad seleccionada. Permite filtrar las calles a medida que el usuario escribe.
- **Número y Número Local:** Campos numéricos para la dirección.
- **Estado:** `RadioListTile` para seleccionar si el comercio está "Abierto" o "Temporalmente cerrado".
- **Checkboxes:** Para indicar si el comercio tiene "Certificado de habilitación", "Comprobantes de pago de Seg e Higiene" y "Servicio de delivery".
- **Rubros Habilitados, Rubros Explotados, Elementos de Publicidad, Observaciones:** Campos de texto multilínea para detalles adicionales.
- **Gestión de Fotos (`_buildFotos`, `_sacarFoto`):**
- La sección "FOTOS" permite al usuario tomar fotografías usando la cámara del dispositivo (`ImagePicker`).
- Las fotos tomadas se añaden a una lista y se muestran en una cuadrícula. Cada foto en la cuadrícula se puede tocar para verla en grande o eliminarla.


- **Botón "GUARDAR" (`guardarTodo`):**
1. **Validación del Formulario:** Llama a `_validarFormulario()` para verificar que todos los campos obligatorios estén completos. 
2. **Verificación de Ubicación:** Si el formulario es válido, vuelve a verificar los permisos de ubicación y obtiene la posición GPS actual (`getCurrentPosition`). Si no se puede obtener la ubicación, muestra un `dialogAceptar`.
3. **Envío de Datos (`http.MultipartRequest`):** Construye una petición `MultipartRequest` para enviar todos los datos del formulario (incluyendo la latitud y longitud obtenidas) y las fotos adjuntas al endpoint `https://backend.sim.lacosta.gob.ar/recursos/guardarDatosFicha`. El token de autorización (`globals.miTokenGlobal`) se incluye en los headers.
- **Botón de Salir (AppBar):** Un icono de "logout" en la barra de la aplicación que, al ser presionado, muestra un `AlertDialog` para confirmar si el usuario desea cerrar la sesión y salir de la aplicación (`exit(0)`).





[Login Page]
   |--Input--> usuario, contraseña
   |--onPress INGRESAR-->
        |--Verifica Permisos de Ubicación-->
          

[PadronApp (Formulario Principal)]
   |--Input--> Nro. Padrón
   |--onPress Buscar (icono lupa)--> Llama API: traerDatosPadronFicha (POST)
        |--> Autocompleta CUIT, Titular, Nombre Fantasía
        |--Fail (no datos / error)--> Muestra SnackBar "No se encontró información"

   |--Input--> Selección Localidad (Dropdown)
        |--Localidad Seleccionada--> Carga Calles (traerCalle API)
   |--Input--> Selección Calle (Dropdown con búsqueda)

   |--Input--> CUIT, Titular, Nombre de Fantasía, Número, Número Local, Rubros Habilitados, Rubros Explotados, Publicidad, Observaciones
   |--Input--> Selección Estado (Radio: Abierto/Cerrado)
   |--Input--> Checkboxes (Certificado Habilitación, Comprobantes Seg e Higiene, Servicio Delivery)

   |--onPress Icono Cámara--> Tomar Foto
        |--Foto Capturada--> Añade Foto a Lista, muestra en cuadrícula
        |--Foto en Cuadrícula (onTap)--> Muestra foto en grande / Elimina foto

   |--onPress GUARDAR-->
        |--Validación Formulario-->
            |--Campos Faltantes--> Muestra SnackBar "Completar campos"
            |--Formulario Válido-->
                

   |--onPress Icono Logout (AppBar)--> Confirma Salida (AlertDialog)
        |--Cancelar--> Permanece en PadronApp
        |--Salir--> Cierra aplicación







flutter pub get
dart run flutter_launcher_icons

## Getting Started
