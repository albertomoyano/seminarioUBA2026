#!/usr/bin/env bash
# ============================================================
# integridad.sh
# Verifica todas las dependencias externas de gbpublisher
# antes de la instalación de la aplicación.
# Uso: bash integridad.sh
# ============================================================

# --- Colores ---
VERDE="\033[0;32m"
ROJO="\033[0;31m"
AMARILLO="\033[0;33m"
RESET="\033[0m"

# --- Contadores ---
OK=0
FALLO=0

# ============================================================
# Helpers
# ============================================================

verificar_paquete() {
  local nombre="$1"
  local descripcion="$2"
  local accion="$3"
  if dpkg -l "$nombre" 2>/dev/null | grep -qc '^ii' > /dev/null 2>&1; then
    echo -e "  ${VERDE}[OK]${RESET}    $descripcion"
    ((OK++))
  else
    echo -e "  ${ROJO}[FALLO]${RESET} $descripcion"
    echo -e "          → $accion"
    ((FALLO++))
  fi
}

verificar_comando() {
  local comando="$1"
  local descripcion="$2"
  local accion="$3"
  if which "$comando" > /dev/null 2>&1; then
    echo -e "  ${VERDE}[OK]${RESET}    $descripcion"
    ((OK++))
  else
    echo -e "  ${ROJO}[FALLO]${RESET} $descripcion"
    echo -e "          → $accion"
    ((FALLO++))
  fi
}

verificar_jar() {
  local directorio="$1"
  local patron="$2"
  local descripcion="$3"
  local accion="$4"
  if [ -d "$directorio" ] && ls "$directorio"/$patron > /dev/null 2>&1; then
    echo -e "  ${VERDE}[OK]${RESET}    $descripcion"
    ((OK++))
  else
    echo -e "  ${ROJO}[FALLO]${RESET} $descripcion"
    echo -e "          → $accion"
    ((FALLO++))
  fi
}

verificar_python() {
  local modulo="$1"
  local descripcion="$2"
  local accion="$3"
  if python3 -c "import $modulo" > /dev/null 2>&1; then
    echo -e "  ${VERDE}[OK]${RESET}    $descripcion"
    ((OK++))
  else
    echo -e "  ${ROJO}[FALLO]${RESET} $descripcion"
    echo -e "          → $accion"
    ((FALLO++))
  fi
}

# ============================================================
# INICIO
# ============================================================

echo ""
echo "============================================================"
echo "  gbpublisher — Verificación de integridad del sistema"
echo "============================================================"
echo ""

# --- Base de datos ---
echo "Base de datos:"
verificar_paquete "mysql-server" "MySQL Server" \
  "sudo apt install mysql-server"

# --- Java ---
echo ""
echo "Java:"
verificar_comando "java" "Java Runtime Environment" \
  "sudo apt install default-jre"

# --- Saxon-HE ---
echo ""
echo "Saxon-HE:"
verificar_jar "/opt/Saxon-HE" "saxon-he-*.jar" \
  "Saxon-HE XSLT Processor" \
  "1. Descargar JAR desde saxonica.com  2. sudo mkdir -p /opt/Saxon-HE  3. sudo cp saxon-he-*.jar /opt/Saxon-HE/"

# --- Procesadores de documentos ---
echo ""
echo "Procesadores de documentos:"
verificar_paquete "pandoc" "Pandoc" \
  "sudo apt install pandoc"
verificar_paquete "texlive-full" "TeX Live (completo)" \
  "sudo apt install texlive-full"
verificar_paquete "epubcheck" "epubcheck (validador EPUB)" \
  "sudo apt install epubcheck"
verificar_paquete "libimage-exiftool-perl" "exiftool (metadatos XMP)" \
  "sudo apt install libimage-exiftool-perl"

# --- Validadores XML ---
echo ""
echo "Validadores XML:"
verificar_comando "xmllint" "xmllint (validador XML)" \
  "sudo apt install libxml2-utils"
verificar_comando "xsltproc" "xsltproc (XSLT processor)" \
  "sudo apt install xsltproc"

# --- Python / packtools ---
echo ""
echo "Python:"
verificar_python "packtools" "packtools (validador SciELO PS)" \
  "pip install packtools --break-system-packages"

# --- Gambas 3 ---
echo ""
echo "Gambas 3:"
verificar_paquete "gambas3-runtime"          "Gambas3 Runtime"               "sudo apt install gambas3-runtime"
verificar_paquete "gambas3-gb-complex"       "Gambas3 gb.complex"            "sudo apt install gambas3-gb-complex"
verificar_paquete "gambas3-gb-crypt"         "Gambas3 gb.crypt"              "sudo apt install gambas3-gb-crypt"
verificar_paquete "gambas3-gb-db2"           "Gambas3 gb.db2"                "sudo apt install gambas3-gb-db2"
verificar_paquete "gambas3-gb-db2-mysql"     "Gambas3 gb.db2.mysql"          "sudo apt install gambas3-gb-db2-mysql"
verificar_paquete "gambas3-gb-db2-sqlite3"   "Gambas3 gb.db2.sqlite3"        "sudo apt install gambas3-gb-db2-sqlite3"
verificar_paquete "gambas3-gb-dbus"          "Gambas3 gb.dbus"               "sudo apt install gambas3-gb-dbus"
verificar_paquete "gambas3-gb-desktop"       "Gambas3 gb.desktop"            "sudo apt install gambas3-gb-desktop"
verificar_paquete "gambas3-gb-eval-highlight" "Gambas3 gb.eval.highlight"    "sudo apt install gambas3-gb-eval-highlight"
verificar_paquete "gambas3-gb-form"          "Gambas3 gb.form"               "sudo apt install gambas3-gb-form"
verificar_paquete "gambas3-gb-form-dialog"   "Gambas3 gb.form.dialog"        "sudo apt install gambas3-gb-form-dialog"
verificar_paquete "gambas3-gb-form-editor"   "Gambas3 gb.form.editor"        "sudo apt install gambas3-gb-form-editor"
verificar_paquete "gambas3-gb-form-htmlview" "Gambas3 gb.form.htmlview"      "sudo apt install gambas3-gb-form-htmlview"
verificar_paquete "gambas3-gb-form-terminal" "Gambas3 gb.form.terminal"      "sudo apt install gambas3-gb-form-terminal"
verificar_paquete "gambas3-gb-highlight"     "Gambas3 gb.highlight"          "sudo apt install gambas3-gb-highlight"
verificar_paquete "gambas3-gb-image"         "Gambas3 gb.image"              "sudo apt install gambas3-gb-image"
verificar_paquete "gambas3-gb-markdown"      "Gambas3 gb.markdown"           "sudo apt install gambas3-gb-markdown"
verificar_paquete "gambas3-gb-net"           "Gambas3 gb.net"                "sudo apt install gambas3-gb-net"
verificar_paquete "gambas3-gb-net-curl"      "Gambas3 gb.net.curl"           "sudo apt install gambas3-gb-net-curl"
verificar_paquete "gambas3-gb-openssl"       "Gambas3 gb.openssl"            "sudo apt install gambas3-gb-openssl"
verificar_paquete "gambas3-gb-pcre"          "Gambas3 gb.pcre"               "sudo apt install gambas3-gb-pcre"
verificar_paquete "gambas3-gb-qt5"           "Gambas3 gb.qt5"                "sudo apt install gambas3-gb-qt5"
verificar_paquete "gambas3-gb-qt5-ext"       "Gambas3 gb.qt5.ext"            "sudo apt install gambas3-gb-qt5-ext"
verificar_paquete "gambas3-gb-sdl2-audio"    "Gambas3 gb.sdl2.audio"         "sudo apt install gambas3-gb-sdl2-audio"
verificar_paquete "gambas3-gb-settings"      "Gambas3 gb.settings"           "sudo apt install gambas3-gb-settings"
verificar_paquete "gambas3-gb-term"          "Gambas3 gb.term"               "sudo apt install gambas3-gb-term"
verificar_paquete "gambas3-gb-util"          "Gambas3 gb.util"               "sudo apt install gambas3-gb-util"
verificar_paquete "gambas3-gb-util-web"      "Gambas3 gb.util.web"           "sudo apt install gambas3-gb-util-web"
verificar_paquete "gambas3-gb-xml"           "Gambas3 gb.xml"                "sudo apt install gambas3-gb-xml"
verificar_paquete "gambas3-gb-xml-html"      "Gambas3 gb.xml.html"           "sudo apt install gambas3-gb-xml-html"
verificar_paquete "gambas3-gb-xml-rpc"       "Gambas3 gb.xml.rpc"            "sudo apt install gambas3-gb-xml-rpc"
verificar_paquete "gambas3-gb-xml-xslt"      "Gambas3 gb.xml.xslt"           "sudo apt install gambas3-gb-xml-xslt"

# ============================================================
# RESUMEN FINAL
# ============================================================
echo ""
echo "============================================================"
if [ "$FALLO" -eq 0 ]; then
  echo -e "  ${VERDE}Sistema listo: $OK dependencias OK, 0 fallos.${RESET}"
  echo "  gbpublisher puede instalarse."
else
  echo -e "  ${AMARILLO}Resultado: $OK OK — ${ROJO}$FALLO fallo(s)${RESET}"
  echo "  Resolvé los fallos antes de instalar gbpublisher."
fi
echo "============================================================"
echo ""
