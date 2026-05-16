# Parcial — Seminario UBA 2026 · Clave de respuestas

---

## Pregunta 1 — Respuesta correcta: **b**

*El PDF como institución*

**b) El PDF cumple a la vez dos funciones: interfaz de lectura y objeto institucional de validación; la primera ya está siendo reemplazada pero la segunda permanece intacta.**

El artículo argumenta que el PDF cumple dos funciones que el campo trata como si fueran una sola: interfaz de lectura —ya reemplazada en la práctica cotidiana de los lectores jóvenes por el HTML en dispositivos móviles— y objeto institucional de validación —que persiste por razones simbólicas y convencionales del campo académico—. Esa asimetría genera la tensión actual. La analogía con el vinilo sirve para mostrar que los formatos culturalmente dominantes pueden declinar, pero en el caso del PDF el proceso es más complejo porque sus dos funciones no están siendo desplazadas al mismo ritmo.

---

## Pregunta 2 — Respuesta correcta: **c**

*El PDF como institución*

**c) Una limitación de la formación profesional disponible, ya que el campo editorial no incorporó al programador como actor central.**

El texto afirma que «el problema real es histórico y estructural: el campo editorial no incorporó al programador como actor central». Las artes gráficas y la edición construyeron su saber profesional alrededor de herramientas de diseño visual —composición manual, fotocomposición, DTP— sin integrar la lógica de las estructuras y la automatización que maneja quien programa. El resultado es un déficit de competencias específicas para trabajar con formatos fluidos que «se percibe erróneamente como una limitación del formato cuando en realidad es una limitación de la formación profesional».

---

## Pregunta 3 — Respuesta correcta: **b**

*El PDF como institución*

**b) Identificador persistente · XML como fuente canónica · hash criptográfico · HTML como interfaz primaria de lectura.**

El artículo enumera cuatro componentes de la arquitectura alternativa al PDF como objeto institucional:

1. Identificador persistente (DOI, ARK, ORCID para autores).
2. XML como versión de registro / fuente canónica (XML-JATS en el caso de artículos científicos).
3. Hash criptográfico (SHA-256, por ejemplo) publicado junto al identificador como huella de integridad.
4. HTML como interfaz primaria de lectura, con todas las capacidades del ecosistema web.

Esta combinación ya existe como posibilidad técnica completamente madura; lo que falta es que el campo académico la adopte como convención.

---

## Pregunta 4 — Respuesta correcta: **c**

*¿Por qué los flujos de trabajo importan?*

**c) Medical Essays and Observations de la Real Sociedad de Edimburgo (1731).**

El texto señala que «la primera publicación que podría considerarse revisada por pares en el sentido moderno del término fue probablemente Medical Essays and Observations, publicada por la Real Sociedad de Edimburgo en 1731». Las Philosophical Transactions (1665) y el Journal des sçavans (1665) son los pioneros de la comunicación científica formal, pero operaban según el criterio personal del editor sin consulta sistemática a revisores externos. Nature, por su parte, no instituyó la revisión formal por pares hasta 1967.

---

## Pregunta 5 — Respuesta correcta: **c**

*¿Por qué los flujos de trabajo importan?*

**c) Revisión doble ciego, donde las identidades de autores y revisores son mutuamente ocultadas.**

El artículo indica que «el modelo doble ciego es considerado más efectivo por el 76% de investigadores encuestados» (fuente: Publons Global State of Peer Review, 2018), aunque aclara que presenta desafíos prácticos en campos pequeños donde los expertos se conocen entre sí. El modelo simple ciego —donde los revisores conocen la identidad de los autores pero no a la inversa— es el más común en la práctica, pero no el más valorado.

---

## Pregunta 6 — Respuesta correcta: **b**

*Bases de datos en la producción editorial científica*

**b) Los datos se almacenan una sola vez y los demás registros los referencian mediante claves foráneas, evitando redundancia e inconsistencia.**

El artículo explica que la normalización consiste en almacenar «cada hecho exactamente una vez» y referenciar ese almacenamiento donde sea necesario. El ejemplo concreto es el de un autor que cambia de institución: en un sistema normalizado se actualiza un único registro y todos los artículos que lo referencian reflejan automáticamente el cambio, sin necesidad de localizar y corregir cada fila manualmente. Este principio es la base del modelo relacional que domina la industria desde hace más de cincuenta años.

---

## Pregunta 7 — Respuesta correcta: **b**

*Bases de datos en la producción editorial científica*

**b) Los datos viven en la base de datos, estructurados según el modelo relacional; el XML-JATS es una serialización de esos datos para su intercambio e interoperabilidad.**

El artículo es explícito: «el XML-JATS no es el origen de los datos sino su expresión. Los datos viven en la base de datos, estructurados y relacionados según las reglas del modelo relacional. El XML-JATS es una serialización de esos datos en un formato estándar para su intercambio e interoperabilidad. Generar XML-JATS de calidad no es cuestión de aprender a escribir etiquetas XML: es cuestión de tener datos bien estructurados en la base de datos.» Esto también implica que la base de datos debe ser la fuente única de verdad, y el XML un artefacto derivado siempre regenerable.

---

## Pregunta 8 — Respuesta correcta: **b**

*Bases de datos en la producción editorial científica*

**b) Una validación interna (contra la base de datos local para detectar mal asignaciones) y una validación externa (consultando las APIs de los servicios correspondientes para verificar que el identificador existe y corresponde a la entidad declarada).**

El texto describe en detalle los dos niveles. El primero es interno: verifica que el identificador no esté ya registrado en la base de datos local con una asignación incorrecta, es decir, un identificador correcto en su forma pero atribuido a una entidad diferente. El segundo es externo: gbpublisher consulta las APIs de ORCID, ROR y CrossRef para confirmar que el identificador existe y corresponde a la entidad declarada. El artículo también menciona el problema específico de las «concurrencias de ORCID», es decir, autores con más de un ORCID registrado, que la herramienta detecta y presenta al editor para su resolución.

---

## Pregunta 9 — Respuesta correcta: **b**

*El paradigma clave=valor en los lenguajes de marcas*

**b) MARC organizaba los registros bibliográficos mediante campos etiquetados numéricamente, donde cada dato debía estar asociado a un identificador que permitiera su interpretación unívoca.**

El artículo señala que el formato MARC (Machine-Readable Cataloging), desarrollado por la Biblioteca del Congreso de los Estados Unidos a mediados de los años 60, «organizaba los registros bibliográficos mediante campos etiquetados numéricamente, cada uno con indicadores y subcampos que precisaban el tipo de dato contenido». Y agrega: «Aunque su sintaxis difería de la forma canónica clave=valor, el principio subyacente era el mismo: cada dato debía estar asociado a un identificador que permitiera su interpretación unívoca. MARC estableció así un antecedente conceptual fundamental para todo el desarrollo posterior.»

---

## Pregunta 10 — Respuesta correcta: **b**

*Flujos de trabajo y bases de datos*

**b) Proponer una infraestructura regional de publicación científica basada en código abierto y gobernanza comunitaria, como alternativa a la dependencia de actores del Norte Global.**

El artículo sobre bases de datos describe AmeliCA como una iniciativa «impulsada en gran parte por actores latinoamericanos» que «propone una infraestructura regional de publicación científica basada en código abierto y gobernanza comunitaria». Está enmarcada en la respuesta al problema de soberanía de datos: la concentración de infraestructura de indexación y gestión de metadatos en manos de un pequeño número de organizaciones del Norte Global (Clarivate, Elsevier, CrossRef). AmeliCA complementa otras respuestas mencionadas en el texto: el fortalecimiento de OpenAlex, el uso de estándares abiertos (JATS, ORCID, ROR, DOI) y el desarrollo de herramientas de código abierto como OJS y gbpublisher.

---

## Pregunta 11 — Respuesta correcta: **b** *(con nota sobre c)*

*Bibliografía y tipos de entrada en BibTeX/BibLaTeX*

**b) `@inproceedings` — porque el volumen contenedor es las actas del congreso ELPUB 2019 y el DOI (`proceedings.elpub`) lo confirma.**

**Por qué b y no a.** El título del volumen contenedor —*Scholarly Communication in Latin America, Spain, Portugal and the Caribbean*— corresponde al tema y subtítulo de la edición 2019 de ELPUB (Electronic Publishing Conference), no a un libro editado independiente. Ediciones anteriores de ELPUB (p.ej. 2012) se publicaron como libros físicos de IOS Press con ISBN, lo cual genera la tentación legítima de usar `@incollection`. Sin embargo, la edición 2019 se publicó en la plataforma OpenEdition con DOI en el espacio `10.4000/proceedings.elpub`, lo que señala inequívocamente que se trata de actas de congreso. Cuando el volumen contenedor es el resultado de un congreso —aunque tenga título propio y paginación— el tipo correcto es `@inproceedings`.

**Por qué b y no c.** Esta es la parte que el manual de biblatex (págs. 8–32, lectura de Clase 06) aclara explícitamente: en BibTeX y en BibLaTeX, `@conference` es un **alias exacto** de `@inproceedings`. No son tipos distintos; comparten los mismos campos obligatorios y producen exactamente la misma salida. La distinción conceptual que algunos manuales de estilo hacen entre «trabajo en actas» y «trabajo en conferencia sin actas formales» no existe como diferencia de tipo en BibTeX/BibLaTeX. Quien elija `@conference` no comete un error técnico (el resultado es idéntico), pero sí demuestra no haber comprendido que es un alias, no un tipo autónomo.

**Regla de decisión práctica:** si el trabajo figura en un volumen de actas de congreso con DOI propio —aunque ese volumen tenga un título que suene a libro editado—, usar `@inproceedings`. Si el trabajo figura en un libro editado sin vínculo con un congreso, usar `@incollection`.

---

*Clave de corrección rápida:*

| Pregunta | Respuesta |
|----------|-----------|
| 1 | b |
| 2 | c |
| 3 | b |
| 4 | c |
| 5 | c |
| 6 | b |
| 7 | b |
| 8 | b |
| 9 | b |
| 10 | b |
| 11 | b |
