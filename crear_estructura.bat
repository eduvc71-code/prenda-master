@echo off
color 0A
echo ========================================================
echo Creando estructura de directorios para PrendaMaster...
echo ========================================================
echo.

set "BASE_DIR=D:\PrendaMaster"

:: Crear directorio raiz
if not exist "%BASE_DIR%" mkdir "%BASE_DIR%"

:: Crear subdirectorios de lib
echo Creando carpetas...
mkdir "%BASE_DIR%\lib\core\constants"
mkdir "%BASE_DIR%\lib\core\theme"
mkdir "%BASE_DIR%\lib\core\router"
mkdir "%BASE_DIR%\lib\presentation\screens\splash"
mkdir "%BASE_DIR%\lib\presentation\screens\login_pin"
mkdir "%BASE_DIR%\lib\presentation\screens\home"
mkdir "%BASE_DIR%\lib\presentation\screens\clientes"
mkdir "%BASE_DIR%\lib\presentation\screens\prestamos"
mkdir "%BASE_DIR%\lib\presentation\screens\pagos"
mkdir "%BASE_DIR%\lib\presentation\screens\reportes"
mkdir "%BASE_DIR%\lib\presentation\screens\alertas"
mkdir "%BASE_DIR%\lib\presentation\screens\admin"

:: Crear archivos raiz y lib
echo Creando archivos...
type nul > "%BASE_DIR%\pubspec.yaml"
type nul > "%BASE_DIR%\lib\main.dart"
type nul > "%BASE_DIR%\lib\app.dart"

:: Crear archivos core
type nul > "%BASE_DIR%\lib\core\constants\app_constants.dart"
type nul > "%BASE_DIR%\lib\core\theme\app_theme.dart"
type nul > "%BASE_DIR%\lib\core\router\app_router.dart"

:: Crear archivos presentation/screens
type nul > "%BASE_DIR%\lib\presentation\screens\splash\splash_screen.dart"
type nul > "%BASE_DIR%\lib\presentation\screens\login_pin\login_pin_screen.dart"
type nul > "%BASE_DIR%\lib\presentation\screens\home\home_screen.dart"

:: Crear archivos clientes
type nul > "%BASE_DIR%\lib\presentation\screens\clientes\clientes_screen.dart"
type nul > "%BASE_DIR%\lib\presentation\screens\clientes\nuevo_cliente_screen.dart"

:: Crear archivos prestamos
type nul > "%BASE_DIR%\lib\presentation\screens\prestamos\prestamos_screen.dart"
type nul > "%BASE_DIR%\lib\presentation\screens\prestamos\nuevo_prestamo_screen.dart"
type nul > "%BASE_DIR%\lib\presentation\screens\prestamos\detalle_prestamo_screen.dart"

:: Crear otros archivos
type nul > "%BASE_DIR%\lib\presentation\screens\pagos\pago_screen.dart"
type nul > "%BASE_DIR%\lib\presentation\screens\reportes\reportes_screen.dart"
type nul > "%BASE_DIR%\lib\presentation\screens\alertas\alertas_screen.dart"
type nul > "%BASE_DIR%\lib\presentation\screens\admin\backup_screen.dart"

echo.
echo ========================================================
echo ¡Estructura creada exitosamente en %BASE_DIR%!
echo ========================================================
pause