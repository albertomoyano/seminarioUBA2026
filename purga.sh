#!/bin/bash
# ============================================================
# purga.sh
# ============================================================
# DESCRIPCIÓN : Pone al día la base de datos de gbpublisher
#               aplicando dos conjuntos de cambios:
#
#               A) Refinamiento del modelo de autoría y capítulos:
#                    1. capitulos: drop autor_correspondencia
#                    2. capitulo_autor: drop es_autor_correspondencia
#                    3. capitulo_autor: rol_autor → ENUM('autor','traductor')
#                    4. capitulo_autor: add publicar_email
#                    5. libro_autor:    add publicar_email
#                    6. capitulos: drop numero_capitulo
#                       (orden y etiqueta se manejan por el nombre del
#                       archivo .md y el XSLT al maquetar, igual que en
#                       artículos)
#
#               B) Purga de tablas legacy (etapa LaTeX):
#                    7. orden_taller: drop FK
#                       fk_orden_taller_metadatos_titulo
#                    8. orden_taller: drop columna titulo_ot
#                    9. drop tabla metadatos
#                   10. drop tabla libros_latex
#                   11. drop tabla bitacora
#
# USO         : bash purga.sh
# REQUISITO   : Acceso sudo para administrar MySQL.
# IDEMPOTENTE : Sí — cada operación se aplica solo si hace falta.
#               Si se corre dos veces seguidas, la segunda no toca
#               nada. Útil para instalaciones en distintos estados:
#                 - BD virgen: aplica las 11 operaciones.
#                 - BD parcialmente al día: aplica solo lo faltante.
#                 - BD ya al día: sale sin tocar nada.
# ============================================================

# --- COLORES ---
VERDE='\033[0;32m'
ROJO='\033[0;31m'
AMARILLO='\033[1;33m'
NEGRITA='\033[1m'
RESET='\033[0m'

# --- PARÁMETROS ---
DB_NOMBRE="gbpublisher"

# ============================================================
# INICIO
# ============================================================
clear
echo ""
echo -e "${NEGRITA}  gbpublisher — Puesta al día de la base de datos${RESET}"
echo "  $(uname -n)  |  $(date '+%d/%m/%Y %H:%M')"
echo "  ════════════════════════════════════════════════════════════════════"

# ============================================================
# PASO 1 — VERIFICAR QUE MYSQL ESTÁ CORRIENDO
# ============================================================
echo ""
echo -e "${NEGRITA}  Paso 1: Verificando servicio MySQL${RESET}"
echo "  ────────────────────────────────────────────────────────────────────"
if systemctl is-active --quiet mysql; then
  echo -e "  MySQL             ${VERDE}activo${RESET}"
else
  echo -e "  ${ROJO}ERROR: El servicio MySQL no está corriendo.${RESET}"
  echo ""
  echo "  Inicialo con:"
  echo "    sudo systemctl start mysql"
  echo ""
  exit 1
fi

# ============================================================
# PASO 2 — VERIFICAR QUE LA BASE EXISTE
# ============================================================
echo ""
echo -e "${NEGRITA}  Paso 2: Verificando base de datos${RESET}"
echo "  ────────────────────────────────────────────────────────────────────"
EXISTE=$(sudo mysql -Nse "SELECT SCHEMA_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME='${DB_NOMBRE}';" 2>/dev/null)
if [ -z "$EXISTE" ]; then
  echo -e "  ${ROJO}ERROR: No se encontró la base de datos '${DB_NOMBRE}'.${RESET}"
  echo ""
  exit 1
fi
echo -e "  ${DB_NOMBRE}        ${VERDE}encontrada${RESET}"

# ============================================================
# PASO 3 — DETECCIÓN DE ESTADO ACTUAL
# ============================================================
echo ""
echo -e "${NEGRITA}  Paso 3: Estado actual de los objetos a modificar${RESET}"
echo "  ────────────────────────────────────────────────────────────────────"

PENDIENTES=0

# --- HELPERS DE DETECCIÓN ---

existe_fk() {
  local tabla="$1"; local fk="$2"
  sudo mysql -Nse "
    SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
     WHERE CONSTRAINT_SCHEMA='${DB_NOMBRE}'
       AND TABLE_NAME='${tabla}'
       AND CONSTRAINT_NAME='${fk}';" 2>/dev/null
}

# DEVUELVE LA CANTIDAD DE FKs QUE TIENEN A 'col' COMO COLUMNA LOCAL
# (SIN IMPORTAR EL NOMBRE DEL CONSTRAINT). MÁS ROBUSTO QUE existe_fk
# PORQUE EL NOMBRE PUEDE DIFERIR ENTRE MÁQUINAS (NOMBRE AUTO-GENERADO
# POR MARIADB VS NOMBRE EXPLÍCITO).
existe_fk_sobre_columna() {
  local tabla="$1"; local col="$2"
  sudo mysql -Nse "
    SELECT COUNT(DISTINCT CONSTRAINT_NAME) FROM information_schema.KEY_COLUMN_USAGE
     WHERE TABLE_SCHEMA='${DB_NOMBRE}'
       AND TABLE_NAME='${tabla}'
       AND COLUMN_NAME='${col}'
       AND REFERENCED_TABLE_NAME IS NOT NULL;" 2>/dev/null
}

# DEVUELVE LOS NOMBRES DE LAS FKs QUE TIENEN A 'col' COMO COLUMNA LOCAL
# (UNA POR LÍNEA), PARA ITERAR Y DROPEARLAS UNA A UNA.
listar_fks_sobre_columna() {
  local tabla="$1"; local col="$2"
  sudo mysql -Nse "
    SELECT DISTINCT CONSTRAINT_NAME FROM information_schema.KEY_COLUMN_USAGE
     WHERE TABLE_SCHEMA='${DB_NOMBRE}'
       AND TABLE_NAME='${tabla}'
       AND COLUMN_NAME='${col}'
       AND REFERENCED_TABLE_NAME IS NOT NULL;" 2>/dev/null
}

# DEVUELVE LOS NOMBRES DE LOS ÍNDICES (NO-PRIMARY) QUE INCLUYEN A 'col',
# PARA DROPEARLOS CUANDO LA FK YA NO LOS PROTEGE.
listar_indices_sobre_columna() {
  local tabla="$1"; local col="$2"
  sudo mysql -Nse "
    SELECT DISTINCT INDEX_NAME FROM information_schema.STATISTICS
     WHERE TABLE_SCHEMA='${DB_NOMBRE}'
       AND TABLE_NAME='${tabla}'
       AND COLUMN_NAME='${col}'
       AND INDEX_NAME <> 'PRIMARY';" 2>/dev/null
}

existe_columna() {
  local tabla="$1"; local col="$2"
  sudo mysql -Nse "
    SELECT COUNT(*) FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA='${DB_NOMBRE}'
       AND TABLE_NAME='${tabla}'
       AND COLUMN_NAME='${col}';" 2>/dev/null
}

existe_tabla() {
  local tabla="$1"
  sudo mysql -Nse "
    SELECT COUNT(*) FROM information_schema.TABLES
     WHERE TABLE_SCHEMA='${DB_NOMBRE}'
       AND TABLE_NAME='${tabla}';" 2>/dev/null
}

tipo_columna() {
  local tabla="$1"; local col="$2"
  sudo mysql -Nse "
    SELECT COLUMN_TYPE FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA='${DB_NOMBRE}'
       AND TABLE_NAME='${tabla}'
       AND COLUMN_NAME='${col}';" 2>/dev/null
}

filas() {
  local tabla="$1"
  sudo mysql -Nse "SELECT COUNT(*) FROM ${DB_NOMBRE}.${tabla};" 2>/dev/null
}

# --- A) MODELO DE AUTORÍA Y CAPÍTULOS ---

echo ""
echo "  ── A) Refinamiento del modelo ──"
echo ""

# A.1 capitulos: FK(s) sobre autor_correspondencia (cualquier nombre)
FKS_COUNT=$(existe_fk_sobre_columna capitulos autor_correspondencia)
if [ "$FKS_COUNT" -gt "0" ]; then
  echo -e "   1. capitulos.FK sobre autor_correspondencia        ${AMARILLO}presente (${FKS_COUNT}) — se eliminará${RESET}"
  PENDIENTES=$((PENDIENTES+1))
else
  echo -e "   1. capitulos.FK sobre autor_correspondencia        ${VERDE}aplicado${RESET}"
fi

# A.2 capitulos.autor_correspondencia (columna)
if [ "$(existe_columna capitulos autor_correspondencia)" = "1" ]; then
  echo -e "   2. capitulos.autor_correspondencia                 ${AMARILLO}presente — se eliminará${RESET}"
  PENDIENTES=$((PENDIENTES+1))
else
  echo -e "   2. capitulos.autor_correspondencia                 ${VERDE}aplicado${RESET}"
fi

# A.3 capitulo_autor.es_autor_correspondencia
if [ "$(existe_columna capitulo_autor es_autor_correspondencia)" = "1" ]; then
  echo -e "   3. capitulo_autor.es_autor_correspondencia         ${AMARILLO}presente — se eliminará${RESET}"
  PENDIENTES=$((PENDIENTES+1))
else
  echo -e "   3. capitulo_autor.es_autor_correspondencia         ${VERDE}aplicado${RESET}"
fi

# A.4 capitulo_autor.rol_autor (ENUM)
TIPO_ROL=$(tipo_columna capitulo_autor rol_autor)
if [ "$TIPO_ROL" != "enum('autor','traductor')" ]; then
  echo -e "   4. capitulo_autor.rol_autor (ENUM)                 ${AMARILLO}será reducido a ('autor','traductor')${RESET}"
  PENDIENTES=$((PENDIENTES+1))
else
  echo -e "   4. capitulo_autor.rol_autor (ENUM)                 ${VERDE}aplicado${RESET}"
fi

# A.5 capitulo_autor.publicar_email
if [ "$(existe_columna capitulo_autor publicar_email)" = "0" ]; then
  echo -e "   5. capitulo_autor.publicar_email                   ${AMARILLO}falta — se agregará${RESET}"
  PENDIENTES=$((PENDIENTES+1))
else
  echo -e "   5. capitulo_autor.publicar_email                   ${VERDE}aplicado${RESET}"
fi

# A.6 libro_autor.publicar_email
if [ "$(existe_columna libro_autor publicar_email)" = "0" ]; then
  echo -e "   6. libro_autor.publicar_email                      ${AMARILLO}falta — se agregará${RESET}"
  PENDIENTES=$((PENDIENTES+1))
else
  echo -e "   6. libro_autor.publicar_email                      ${VERDE}aplicado${RESET}"
fi

# A.7 capitulos.numero_capitulo
if [ "$(existe_columna capitulos numero_capitulo)" = "1" ]; then
  FILAS_NUMCAP=$(sudo mysql -Nse "SELECT COUNT(*) FROM ${DB_NOMBRE}.capitulos WHERE numero_capitulo IS NOT NULL;" 2>/dev/null)
  echo -e "   7. capitulos.numero_capitulo                       ${AMARILLO}presente — se eliminará${RESET}  (${FILAS_NUMCAP} filas con valor)"
  PENDIENTES=$((PENDIENTES+1))
else
  echo -e "   7. capitulos.numero_capitulo                       ${VERDE}aplicado${RESET}"
fi

# --- B) PURGA LEGACY LATEX ---

echo ""
echo "  ── B) Purga de tablas legacy (etapa LaTeX) ──"
echo ""

# B.8 orden_taller: FK(s) sobre titulo_ot (cualquier nombre)
FKS_OT_COUNT=$(existe_fk_sobre_columna orden_taller titulo_ot)
if [ "$FKS_OT_COUNT" -gt "0" ]; then
  echo -e "   8. orden_taller.FK sobre titulo_ot                 ${AMARILLO}presente (${FKS_OT_COUNT}) — se eliminará${RESET}"
  PENDIENTES=$((PENDIENTES+1))
else
  echo -e "   8. orden_taller.FK sobre titulo_ot                 ${VERDE}aplicado${RESET}"
fi

# B.9 orden_taller.titulo_ot
if [ "$(existe_columna orden_taller titulo_ot)" = "1" ]; then
  FILAS_TITULO=$(sudo mysql -Nse "SELECT COUNT(*) FROM ${DB_NOMBRE}.orden_taller WHERE titulo_ot IS NOT NULL;" 2>/dev/null)
  echo -e "   9. orden_taller.titulo_ot                          ${AMARILLO}presente — se eliminará${RESET}  (${FILAS_TITULO} filas con valor)"
  PENDIENTES=$((PENDIENTES+1))
else
  echo -e "   9. orden_taller.titulo_ot                          ${VERDE}aplicado${RESET}"
fi

# B.10 / B.11 / B.12 tablas legacy
TABLA_NUM=10
for TABLA in metadatos libros_latex bitacora; do
  if [ "$(existe_tabla "$TABLA")" = "1" ]; then
    F=$(filas "$TABLA")
    printf "  %2d. tabla %-32s ${AMARILLO}presente — se eliminará${RESET}  (%s filas)\n" "$TABLA_NUM" "${TABLA}" "${F}"
    PENDIENTES=$((PENDIENTES+1))
  else
    printf "  %2d. tabla %-32s ${VERDE}aplicado${RESET}\n" "$TABLA_NUM" "${TABLA}"
  fi
  TABLA_NUM=$((TABLA_NUM+1))
done

# ============================================================
# Si no hay pendientes, salir.
# ============================================================
if [ "$PENDIENTES" = "0" ]; then
  echo ""
  echo "  ════════════════════════════════════════════════════════════════════"
  echo -e "  ${VERDE}${NEGRITA}La base de datos ya está al día.${RESET}"
  echo "  ════════════════════════════════════════════════════════════════════"
  echo ""
  exit 0
fi

# ============================================================
# PASO 4 — CONFIRMAR
# ============================================================
echo ""
echo -e "${NEGRITA}  Paso 4: Confirmación${RESET}"
echo "  ────────────────────────────────────────────────────────────────────"
echo ""
echo -e "  ${AMARILLO}${NEGRITA}ATENCIÓN — OPERACIÓN DESTRUCTIVA${RESET}"
echo ""
echo "  Se aplicarán ${PENDIENTES} cambio(s) sobre los objetos marcados arriba."
echo "  Esta operación NO se puede deshacer."
echo ""
read -rp "  ¿Confirmar? Escribí 'si' para continuar: " CONFIRMAR
if [ "$CONFIRMAR" != "si" ]; then
  echo ""
  echo "  Operación cancelada."
  echo ""
  exit 0
fi

# ============================================================
# PASO 5 — APLICAR CAMBIOS
# ============================================================
echo ""
echo -e "${NEGRITA}  Paso 5: Aplicando cambios${RESET}"
echo "  ────────────────────────────────────────────────────────────────────"

# ────────────────────────────────────────────────────────────────────
# A.1 / A.1b — DROP DINÁMICO DE TODAS LAS FKs E ÍNDICES SOBRE LA COLUMNA
# capitulos.autor_correspondencia (SIN IMPORTAR NOMBRE)
# Se hace ANTES del heredoc porque MySQL no permite ejecutar múltiples
# statements desde un solo PREPARE/EXECUTE.
# ────────────────────────────────────────────────────────────────────

# A.1: drop CADA FK sobre capitulos.autor_correspondencia
while IFS= read -r FK_NAME; do
  [ -z "$FK_NAME" ] && continue
  echo "   • Drop FK capitulos.${FK_NAME}"
  sudo mysql "$DB_NOMBRE" -e "ALTER TABLE capitulos DROP FOREIGN KEY \`${FK_NAME}\`;" 2>&1 \
    | grep -v "^$" || true
done < <(listar_fks_sobre_columna capitulos autor_correspondencia)

# A.1b: drop CADA índice no-PRIMARY sobre capitulos.autor_correspondencia
while IFS= read -r IDX_NAME; do
  [ -z "$IDX_NAME" ] && continue
  echo "   • Drop INDEX capitulos.${IDX_NAME}"
  sudo mysql "$DB_NOMBRE" -e "ALTER TABLE capitulos DROP INDEX \`${IDX_NAME}\`;" 2>&1 \
    | grep -v "^$" || true
done < <(listar_indices_sobre_columna capitulos autor_correspondencia)

# B.8: drop CADA FK sobre orden_taller.titulo_ot
while IFS= read -r FK_NAME; do
  [ -z "$FK_NAME" ] && continue
  echo "   • Drop FK orden_taller.${FK_NAME}"
  sudo mysql "$DB_NOMBRE" -e "ALTER TABLE orden_taller DROP FOREIGN KEY \`${FK_NAME}\`;" 2>&1 \
    | grep -v "^$" || true
done < <(listar_fks_sobre_columna orden_taller titulo_ot)

# B.8b: drop CADA índice no-PRIMARY sobre orden_taller.titulo_ot
while IFS= read -r IDX_NAME; do
  [ -z "$IDX_NAME" ] && continue
  echo "   • Drop INDEX orden_taller.${IDX_NAME}"
  sudo mysql "$DB_NOMBRE" -e "ALTER TABLE orden_taller DROP INDEX \`${IDX_NAME}\`;" 2>&1 \
    | grep -v "^$" || true
done < <(listar_indices_sobre_columna orden_taller titulo_ot)

# ────────────────────────────────────────────────────────────────────
# RESTO DE OPERACIONES — EN UN SOLO HEREDOC TRANSACCIONAL
# A.2, A.3, A.4, A.5, A.6, A.7, B.9, B.10/11/12
# ────────────────────────────────────────────────────────────────────

sudo mysql "$DB_NOMBRE" <<'EOSQL'
SET FOREIGN_KEY_CHECKS = 0;

-- ─────────────────────────────────────────────────────────────
-- A) MODELO DE AUTORÍA Y CAPÍTULOS
-- ─────────────────────────────────────────────────────────────

-- A.2 capitulos: drop columna autor_correspondencia (si existe)
SET @sql = (
  SELECT IF(COUNT(*) > 0,
    'ALTER TABLE capitulos DROP COLUMN autor_correspondencia',
    'SELECT 1')
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'capitulos'
    AND COLUMN_NAME = 'autor_correspondencia'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- A.3 capitulo_autor: drop columna es_autor_correspondencia (si existe)
SET @sql = (
  SELECT IF(COUNT(*) > 0,
    'ALTER TABLE capitulo_autor DROP COLUMN es_autor_correspondencia',
    'SELECT 1')
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'capitulo_autor'
    AND COLUMN_NAME = 'es_autor_correspondencia'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- A.4a Migrar valores de rol_autor fuera del ENUM nuevo a 'autor'.
--      Seguro de correr siempre: si el ENUM ya está reducido, no hay filas para mapear.
UPDATE capitulo_autor
   SET rol_autor = 'autor'
   WHERE rol_autor NOT IN ('autor','traductor');

-- A.4b capitulo_autor: reducir ENUM rol_autor (solo si todavía no está reducido)
SET @sql = (
  SELECT IF(COLUMN_TYPE <> "enum('autor','traductor')",
    "ALTER TABLE capitulo_autor MODIFY COLUMN rol_autor ENUM('autor','traductor') NULL DEFAULT 'autor'",
    'SELECT 1')
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'capitulo_autor'
    AND COLUMN_NAME = 'rol_autor'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- A.5 capitulo_autor: add publicar_email (si no existe)
SET @sql = (
  SELECT IF(COUNT(*) = 0,
    'ALTER TABLE capitulo_autor ADD COLUMN publicar_email TINYINT(1) NULL DEFAULT 0 AFTER email_momento',
    'SELECT 1')
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'capitulo_autor'
    AND COLUMN_NAME = 'publicar_email'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- A.6 libro_autor: add publicar_email (si no existe)
SET @sql = (
  SELECT IF(COUNT(*) = 0,
    'ALTER TABLE libro_autor ADD COLUMN publicar_email TINYINT(1) NULL DEFAULT 0 AFTER email_momento',
    'SELECT 1')
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'libro_autor'
    AND COLUMN_NAME = 'publicar_email'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- A.7 capitulos: drop numero_capitulo (si existe)
-- El orden de los capítulos se deriva del nombre del archivo .md y la
-- etiqueta visible ("1", "I", "Apéndice A") se genera en el XSLT/template
-- al maquetar, igual que en artículos. La columna INT es redundante.
SET @sql = (
  SELECT IF(COUNT(*) > 0,
    'ALTER TABLE capitulos DROP COLUMN numero_capitulo',
    'SELECT 1')
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'capitulos'
    AND COLUMN_NAME = 'numero_capitulo'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ─────────────────────────────────────────────────────────────
-- B) PURGA LEGACY LATEX
-- (B.8 y B.8b YA SE EJECUTARON EN BASH ARRIBA, FUERA DEL HEREDOC)
-- ─────────────────────────────────────────────────────────────

-- B.9 orden_taller: drop columna titulo_ot (si existe)
SET @sql = (
  SELECT IF(COUNT(*) > 0,
    'ALTER TABLE orden_taller DROP COLUMN titulo_ot',
    'SELECT 1')
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'orden_taller'
    AND COLUMN_NAME = 'titulo_ot'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- B.10 / B.11 / B.12 — drop tablas legacy
DROP TABLE IF EXISTS metadatos;
DROP TABLE IF EXISTS libros_latex;
DROP TABLE IF EXISTS bitacora;

SET FOREIGN_KEY_CHECKS = 1;
EOSQL

if [ $? -ne 0 ]; then
  echo -e "  ${ROJO}ERROR: Falló la aplicación de cambios.${RESET}"
  echo "  Revisá los mensajes de MySQL arriba."
  echo ""
  exit 1
fi

echo -e "  Cambios aplicados   ${VERDE}OK${RESET}"

# ============================================================
# PASO 6 — VERIFICACIÓN POSTERIOR
# ============================================================
echo ""
echo -e "${NEGRITA}  Paso 6: Verificación${RESET}"
echo "  ────────────────────────────────────────────────────────────────────"

TODO_OK=1

# --- A) MODELO DE AUTORÍA Y CAPÍTULOS ---

echo ""
echo "  ── A) Refinamiento del modelo ──"
echo ""

[ "$(existe_fk_sobre_columna capitulos autor_correspondencia)" = "0" ] \
  && echo -e "   1. capitulos.FK sobre autor_correspondencia        ${VERDE}OK${RESET}" \
  || { echo -e "   1. capitulos.FK sobre autor_correspondencia        ${ROJO}FALLA${RESET}"; TODO_OK=0; }

[ "$(existe_columna capitulos autor_correspondencia)" = "0" ] \
  && echo -e "   2. capitulos.autor_correspondencia                 ${VERDE}OK${RESET}" \
  || { echo -e "   2. capitulos.autor_correspondencia                 ${ROJO}FALLA${RESET}"; TODO_OK=0; }

[ "$(existe_columna capitulo_autor es_autor_correspondencia)" = "0" ] \
  && echo -e "   3. capitulo_autor.es_autor_correspondencia         ${VERDE}OK${RESET}" \
  || { echo -e "   3. capitulo_autor.es_autor_correspondencia         ${ROJO}FALLA${RESET}"; TODO_OK=0; }

TIPO_ROL_POST=$(tipo_columna capitulo_autor rol_autor)
[ "$TIPO_ROL_POST" = "enum('autor','traductor')" ] \
  && echo -e "   4. capitulo_autor.rol_autor (ENUM)                 ${VERDE}OK${RESET}" \
  || { echo -e "   4. capitulo_autor.rol_autor (ENUM)                 ${ROJO}FALLA${RESET}  (tipo actual: ${TIPO_ROL_POST})"; TODO_OK=0; }

[ "$(existe_columna capitulo_autor publicar_email)" = "1" ] \
  && echo -e "   5. capitulo_autor.publicar_email                   ${VERDE}OK${RESET}" \
  || { echo -e "   5. capitulo_autor.publicar_email                   ${ROJO}FALLA${RESET}"; TODO_OK=0; }

[ "$(existe_columna libro_autor publicar_email)" = "1" ] \
  && echo -e "   6. libro_autor.publicar_email                      ${VERDE}OK${RESET}" \
  || { echo -e "   6. libro_autor.publicar_email                      ${ROJO}FALLA${RESET}"; TODO_OK=0; }

[ "$(existe_columna capitulos numero_capitulo)" = "0" ] \
  && echo -e "   7. capitulos.numero_capitulo                       ${VERDE}OK${RESET}" \
  || { echo -e "   7. capitulos.numero_capitulo                       ${ROJO}FALLA${RESET}"; TODO_OK=0; }

# --- B) PURGA LEGACY ---

echo ""
echo "  ── B) Purga de tablas legacy (etapa LaTeX) ──"
echo ""

[ "$(existe_fk_sobre_columna orden_taller titulo_ot)" = "0" ] \
  && echo -e "   8. orden_taller.FK sobre titulo_ot                 ${VERDE}OK${RESET}" \
  || { echo -e "   8. orden_taller.FK sobre titulo_ot                 ${ROJO}FALLA${RESET}"; TODO_OK=0; }

[ "$(existe_columna orden_taller titulo_ot)" = "0" ] \
  && echo -e "   9. orden_taller.titulo_ot                          ${VERDE}OK${RESET}" \
  || { echo -e "   9. orden_taller.titulo_ot                          ${ROJO}FALLA${RESET}"; TODO_OK=0; }

TABLA_NUM=10
for TABLA in metadatos libros_latex bitacora; do
  if [ "$(existe_tabla "$TABLA")" = "0" ]; then
    printf "  %2d. tabla %-32s ${VERDE}OK${RESET}\n" "$TABLA_NUM" "${TABLA}"
  else
    printf "  %2d. tabla %-32s ${ROJO}FALLA${RESET}\n" "$TABLA_NUM" "${TABLA}"
    TODO_OK=0
  fi
  TABLA_NUM=$((TABLA_NUM+1))
done

# --- CONTEO FINAL ---

TOTAL_TABLAS=$(sudo mysql -Nse "
  SELECT COUNT(*) FROM information_schema.TABLES
   WHERE TABLE_SCHEMA = '${DB_NOMBRE}';" 2>/dev/null)
echo ""
echo "  Total de tablas en ${DB_NOMBRE}: ${NEGRITA}${TOTAL_TABLAS}${RESET}  (esperado: 30)"

# ============================================================
# RESUMEN FINAL
# ============================================================
echo ""
echo "  ════════════════════════════════════════════════════════════════════"
if [ "$TODO_OK" = "1" ]; then
  echo -e "  ${VERDE}${NEGRITA}Base de datos al día.${RESET}"
else
  echo -e "  ${ROJO}${NEGRITA}Algunos cambios no se aplicaron correctamente.${RESET}"
  echo "  Revisá los mensajes marcados con FALLA arriba."
fi
echo "  ════════════════════════════════════════════════════════════════════"
echo ""

exit 0
