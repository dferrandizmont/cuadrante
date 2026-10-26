# Glosario de terminología — catalán (ca), gallego (gl), euskera (eu) e inglés (en)

Base para traducir Cuadrante (`app/lib/l10n/app_es.arb`). **«Cuadrante» se queda como marca en los cuatro idiomas**; aquí se
da el nombre común. Los textos de la app están en español, tuteo, tono cercano y vocabulario del sector.

## Cómo leer este documento (y qué NO está verificado)

Marcas de fiabilidad en cada fila:

- **[V]** visto en una fuente institucional durante la investigación (enlace en «Fuentes verificadas»).
- **[C]** uso conocido de la institución o del sector, **no comprobado en línea** (los buscadores devolvieron poco y las
  bases terminológicas no se dejan consultar por herramienta: Euskalterm devolvió 404, Cercaterm 401, Elhuyar 404 y Termigal
  no se pudo abrir). Hay que contrastarlo en la base indicada antes de congelar la traducción.
- **[P]** propuesta: no hay equivalente establecido que yo haya podido confirmar. Pasa por un hablante nativo.

Orden de prioridad de las fuentes: banco terminológico oficial > documentos de la administración sanitaria/policial del
territorio > diccionario normativo > uso real en apps (Android/iOS localizados).

Una norma práctica para todo el glosario: **la app es de uso diario y de lectura rápida**, así que ante dos opciones
correctas gana la más corta y la que usan los propios trabajadores del sector, aunque el banco terminológico prefiera
una más larga (la larga puede ir en el texto de ayuda).

---

## 1. Turnos y trabajo

| es | ca | gl | eu | en | Nota |
|---|---|---|---|---|---|
| turno | torn | quenda | txanda | shift | gl **[V]** (RAG: *quenda*, «tempo en que lle corresponde a unha persoa facer… segundo unha repartición previa»; SERGAS «Traballo a quendas»). eu **[V]** (Osakidetza/BOPV: *txanda*, *lan-txanda*, *gaueko txanda*). ca **[C]** (*torn*, ICS/Mossos/Bombers). |
| cuadrante (nombre común) | quadrant (de torns) | cadro de quendas **[P]** | txanden egutegia **[P]** | shift schedule (US) · roster / rota (UK) | ca *quadrant* se usa tal cual en Mossos y empresas **[C]**. eu: *lan-egutegia* es el término oficial para el «calendario de trabajo/cuadrante» de la Ertzaintza **[V]** (la Dirección de RR. HH. de Seguridad gestiona «Ertzaintzaren lan-egutegiak»), pero también significa «calendario laboral anual»; por eso para el cuadrante personal se propone *txanden egutegia*. gl: «cadrante» existe en el RAG con otro sentido, por eso *cadro de quendas*. en: «schedule» es lo que entiende todo el mundo; «roster/rota» es habitual en la sanidad británica. |
| rotación | rotació | rotación | txandaketa | rotation | eu **[V]** (Ertzaintza, BOPV: «txandakatuko dituzte» = se rotarán). |
| patrón (de turnos) | patró | patrón | eredua (txandaketa-eredua) | pattern / shift pattern | UK «shift pattern» es la expresión corriente; US «schedule». gl alternativa: *modelo*. |
| correturnos (sistema) | torns rotatius | quendas rotativas | txanda birakariak (*txanda errotatiboak*) **[P]** | rotating shifts | En la app «correturnos» es el sistema M/T/N de industria. El otro sentido (persona que cubre turnos ajenos) no se usa: ca *treballador/a de relleu*, en *relief worker*. |
| mañana (turno) | Matí | Mañá | Goiza | Morning | **Choque con «mañana = día siguiente»** (la app ya lo resuelve con «Mañana ({date})»): en ca y eu no hay choque (*demà* / *bihar*); en gl *mañá* tiene los dos sentidos igual que en español, así que mantén la fecha entre paréntesis. |
| tarde (turno) | Tarda | Tarde | Arratsaldea | Afternoon | UK sanidad: *Early / Late / Night* (M 08–15 = Early, T 15–22 = Late). US: *Day / Evening / Night*. Para el `en` neutro: Morning / Afternoon / Night. |
| noche (turno) | Nit | Noite | Gaua | Night | |
| códigos de 1 letra de las plantillas | M / T / N | M / T / N | **Goi / Arr / Gau** | M / A / N | **eu: G (Goiza) y G (Gaua) chocan**, y A (Arratsaldea) es ambigua; usa códigos de 3 letras (`Goi`, `Arr`, `Gau`; el campo admite hasta 3). |
| turno partido | torn partit | quenda partida | txanda zatitua | split shift | **[C]** *jornada partida* → ca *jornada partida*, gl *xornada partida*, eu *lanaldi zatitua*. |
| guardia (24 h) | guàrdia (de 24 h) | garda (de 24 h) | guardia (24 orduko) · alt. zaintza **[C]** | 24-hour shift · «on call» (ver nota) | gl: SERGAS usa *garda*, *garda de presenza física*, *garda localizada* **[C]**. eu: en Osakidetza se oye y escribe *guardia* / *guardia fisikoa* / *guardia lokalizatua* **[C]**; *zaintza* es la voz euskaldun propuesta por el banco pero no es la que usan los sanitarios: **recomendado *guardia*** y confirmar con nativo. en: «on-call» en UK/US significa *localizada*, no presencial; para los 24 h presenciales, «24-hour shift» (bomberos) o «24 h call shift» (médicos, US *call*). |
| saliente | Sortint | Saínte | Gau-ondokoa **[P]** | Post-night · Post-call | ca: «sortint de nit / de guàrdia» es la jerga de ICS **[C]**. gl: *saínte* (de garda / de noite) es uso SERGAS **[C]** y adjetivo del RAG. eu: no hay término establecido; descripción larga *gaueko txandaren ondorengo atsedena*; etiqueta corta propuesta *Gau-ondokoa*. en: *post-call* (médicos, US), *post-nights* / *post-night day* (enfermería UK). |
| libre / día libre | lliure / dia lliure | libre / día libre | libre / egun librea | Off / Day off | eu: *jai-eguna* significa «festivo», **no lo uses para día libre**. |
| descanso | descans | descanso | atsedena | Rest | Descanso **dentro** de un turno partido o descanso no pagado: ca *pausa*, gl *pausa*, eu *etenaldia*, en *break* («unpaid break»). |
| libranza | dia de descans | libranza | libre-eguna **[P]** | Rest day (UK) · Day off | Es sinónimo de «día libre» en policía y bomberos. gl *libranza* sí se usa **[C]**; en ca no hay palabra viva distinta de *dia de descans*. Si no hay un uso distinto en la app, unifica con «libre». |
| doblar turno / doble turno | doblar torn / doble torn | dobrar quenda / dobre quenda | txanda bikoiztu / txanda bikoitza | Double shift | Acción «Doblar con otro turno» = añadir un segundo turno el mismo día: *Afegeix un segon torn* / *Engade unha segunda quenda* / *Gehitu bigarren txanda* / *Add a second shift*. |
| cambio de turno | canvi de torn | cambio de quenda | txanda-trukea | shift swap | «cambio con…»: *Canvi amb…* / *Cambio con…* / *Trukea: …* / *Swap with…*. eu: no pongas nombres propios con sufijo (*Mikel-ekin*): usa dos puntos. |
| horas extra | hores extra | horas extra | aparteko orduak | overtime | eu **[V]** (Osakidetza/Euskadi: «aparteko orduak»). ca oficial *hores extraordinàries*, gl oficial *horas extraordinarias*; en la UI vale *hores extra* / *horas extra* (uso real). |
| salida anticipada | sortida anticipada | saída anticipada | irteera aurreratua | early leave | La cadena «Salí antes» (1.ª persona): ca *He sortit abans*, gl *Saín antes*, eu *Lehenago atera naiz*, en *Left early*. |
| jornada | jornada | xornada | lanaldia | working day · workday | gl *xornada* **[C]** (grafía normativa). eu *lanaldi* = jornada laboral, *lan-jardunaldia* = jornada de trabajo extensa; *lanaldia* es lo normal. |
| convenio (colectivo) | conveni (col·lectiu) | convenio (colectivo) | hitzarmen kolektiboa | collective agreement (UK) · union contract / CBA (US) | eu *hitzarmena* **[V]** (BFA, Gobierno Vasco). |
| plus / pluses | plus · complement | plus · complemento | osagarria (*plusa* en coloquial) | allowance · premium · pay supplement | UK «allowance» (p. ej. *unsocial hours payment*); US «differential». |
| nocturnidad | nocturnitat | nocturnidade | gaueko osagarria (*gaueko plusa*) | night differential (US) · night allowance / enhancement (UK) | eu: *gaueko osagarria* **[C]**. |
| horas nocturnas | hores nocturnes | horas nocturnas | gaueko orduak | night hours | |
| festivo | festiu | festivo | jaiegun | public holiday | gl: no uses *feriado* (portugués). en: *holiday* en UK/US coloquial, pero choca con vacaciones: usa *public holiday* y reserva *vacation* para el otro sentido. |
| festivo local | festiu local | festivo local | tokiko jaiegun | local holiday | |
| festivo autonómico | festiu autonòmic | festivo autonómico | erkidegoko jaiegun | regional holiday | «Autonomous community» no se dice en inglés cotidiano; *regional*. |
| festivo propio (añadido por el usuario) | festiu propi | festivo propio | jaiegun pertsonala **[P]** | Custom holiday | |

## 2. Ausencias

| es | ca | gl | eu | en | Nota |
|---|---|---|---|---|---|
| vacaciones | vacances | vacacións | oporrak | vacation (US) · annual leave (UK) | Recomendado **Vacation**: evita el choque con «holiday» (festivo) que hay en UK. |
| baja (médica) | baixa (mèdica) | baixa (médica) | baja medikoa · formal: aldi baterako ezintasuna (ABE) | sick leave | IT = *incapacitat temporal* / *incapacidade temporal* / *aldi baterako ezintasuna* **[C]**. en: *medical leave* en US abarca también permisos tipo FMLA; *sick leave* es más claro. |
| moscoso / asuntos propios / libre disposición | dies de lliure disposició · assumptes particulars · «moscosos» | días de libre disposición | norberaren arazoetarako egunak **[V parcial]** | personal days (US) · discretionary / personal leave (UK) | «Moscoso» es argot español; en las tres lenguas cooficiales la gente también dice *els moscosos* / *os moscosos* **[C]**. eu: *Norberaren arazoetarako lizentzia* aparece en un convenio público (BFA, art. 65) **[V]**, no de Osakidetza; alternativa *norberaren gaietarako*. Etiqueta corta de botón: *Lliure disposició* / *Libre disposición* / *Norberaren egunak* **[P]**. |
| permiso | permís | permiso | baimena | leave · time off | |
| ausencia | absència | ausencia | absentzia | absence | Categoría de turno «Ausencia». Alternativa en: *Time off*. |

## 3. Profesiones

| es | ca | gl | eu | en | Nota |
|---|---|---|---|---|---|
| enfermería | infermeria | enfermaría | erizaintza | nursing | |
| enfermero/a | infermer/a | enfermeiro/a | erizaina | nurse | |
| TCAE / auxiliar | TCAI (tècnic/a en cures auxiliars d'infermeria) | TCAE | erizaintzako laguntzailea **[V]** | nursing assistant (UK: healthcare assistant, HCA · US: CNA) | En Cataluña la sigla es **TCAI**, no TCAE **[C]**. eu: *Erizaintzako Laguntzailea* es la categoría de Osakidetza (grupo «Teknikari Laguntzaile Sanitarioak», BOPV 2026) **[V]**; no se encontró sigla en euskera. |
| médico/a | metge/metgessa | médico/a | medikua | doctor · physician | |
| celador/a | zelador/a | celador/a | zeladorea **[V]** | hospital porter (UK) · orderly / patient transporter (US) | ca *zelador* se usa en el ICS **[C]**. eu: *Zeladorea* / *Zeladoreen arduraduna* en convocatorias de Osakidetza (BOPV 2022, 2026) **[V]**. |
| policía | policia | policía | polizia (ertzaina, udaltzaina) | police officer | Mossos / Ertzaintza / Policía Galega: nombres propios, no se traducen. |
| bombero/a | bomber/a | bombeiro/a | suhiltzailea | firefighter | |
| vigilante | vigilant (de seguretat) | vixiante | zaindaria · segurtasun-zaindaria | security guard | |
| operario/a | operari/ària | operario/a | langilea · operarioa | operator · production worker | |
| Guardia Civil | Guàrdia Civil | Garda Civil | Guardia Zibila | Guardia Civil | Nombre propio. |

## 4. Interfaz y funciones

| es | ca | gl | eu | en | Nota |
|---|---|---|---|---|---|
| copia de seguridad | còpia de seguretat | copia de seguranza | babeskopia | backup | Nunca «sync/sincronizar». |
| restaurar | restaura | restaurar | leheneratu | restore | |
| exportar / importar | exporta / importa | exportar / importar | esportatu / inportatu | export / import | eu **[C]** (informática en euskera usa *esportatu/inportatu*). |
| widget | **widget** | **widget** | widgeta | widget | **Decidido (23-oct): «widget» en todos los idiomas** (el lanzador del móvil ya dice «widget»; H-T21-4). Antes: ca *giny* (TERMCAT), gl *trebello*. eu: *widget(a)*. |
| aviso / alarma / recordatorio | avís / alarma / recordatori | aviso / alarma / recordatorio | abisua / alarma / gogorarazpena | notification / alarm / reminder | |
| posponer | ajorna (alarma) · posposa | adiar | atzeratu | snooze (alarma) · postpone | |
| pintar (días) | pinta | pintar | margotu | paint | Modo pintar: *Mode pintar* / *Modo pintar* / *Margotze modua* / *Paint mode*. Alternativa en: *Assign*. |
| deshacer / rehacer | desfés / refés | desfacer / refacer | desegin / berregin | undo / redo | |
| resumen | resum | resumo | laburpena | summary | |
| agenda | agenda | axenda | agenda | agenda | gl normativa: *axenda* **[C]**. |
| calendario | calendari | calendario | egutegia | calendar | |
| ajustes | configuració | configuración | ezarpenak | settings | Es lo que usan Android/iOS en esos idiomas **[C]**. |
| primer uso (onboarding) | benvinguda | benvida | ongi etorria | welcome · setup | No traducir «primer uso» literalmente. |
| guardar / cancelar / borrar / cerrar | desa / cancel·la / esborra / tanca | gardar / cancelar / borrar / pechar | gorde / utzi / ezabatu / itxi | save / cancel / delete / close | |
| archivar / recuperar | arxiva / recupera | arquivar / recuperar | artxibatu / berreskuratu | archive / restore | |
| nota | nota | nota | oharra | note | |
| hoy / mañana (día) | avui / demà | hoxe / mañá | gaur / bihar | today / tomorrow | |

## 5. Calendario: días y meses

**Cabecera de 1 letra (semana desde el lunes).** Los tres idiomas no coinciden con el español:

| es | L M X J V S D |
|---|---|
| ca | **dl dt dc dj dv ds dg** (2 letras, como eu; antes L M X J V S G, donde diumenge = G; H-T21-5) — abreviaturas habituales |
| gl | **L M M X V S D** (martes = M, mércores = M, xoves = X) — CLDR y calendarios de la Xunta. Las dos M chocan: si molesta, M/C **[P]**, pero lo normal es la M repetida. |
| eu | **No hay 1 letra utilizable**: A A A O O L I. Usa **2 letras: Al Ar Az Og Or Lr Ig** (CLDR: al., ar., az., og., or., lr., ig.). |
| en | M T W T F S S (T y S repetidas; para accesibilidad, el nombre completo ya va en `Semantics`) |

**Días (3 letras / nombre).** ca: dl. dt. dc. dj. dv. ds. dg. (dilluns…diumenge) · gl: luns, mar., mér., xov., ven., sáb., dom. (luns, martes, mércores, xoves, venres, sábado, domingo) · eu: astelehena, asteartea, asteazkena, osteguna, ostirala, larunbata, igandea (abrev. CLDR: al. ar. az. og. or. lr. ig.) · en: Mon…Sun.

**Meses de 3 letras** (los de tabla con puntos son los CLDR; en la app mejor sin punto y siempre minúscula en ca/gl/eu):

| es | ene | feb | mar | abr | may | jun | jul | ago | sep | oct | nov | dic |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| ca | gen | feb | mar | abr | mai | jun | jul | ago | set | oct | nov | des |
| gl | xan | feb | mar | abr | mai | xuñ | xul | ago | set | out | nov | dec |
| eu | urt | ots | mar | api | mai | eka | uzt | abu | ira | urr | aza | abe |
| en | Jan | Feb | Mar | Apr | May | Jun | Jul | Aug | Sep | Oct | Nov | Dec |

Nombres completos. ca: gener, febrer, març, abril, maig, juny, juliol, agost, setembre, octubre, novembre, desembre. gl: xaneiro, febreiro, marzo, abril, maio, xuño, xullo, agosto, setembro, outubro, novembro, decembro. eu: urtarrila, otsaila, martxoa, apirila, maiatza, ekaina, uztaila, abuztua, iraila, urria, azaroa, abendua (EHU confirma que *urtarril, otsail, apiril, maiatz, ekain, uztail, irail* son las formas con consonante final que dan problemas de declinación **[V]**). Las abreviaturas ca/gl/eu vienen de CLDR/`intl` y de la tradición de calendarios **[C]**; las de 3 letras que no están en CLDR (ca *mai*, gl *xuñ*) son mías **[P]**.

**Fecha «lunes, 20 de octubre»** (usa siempre `DateFormat` con la localización; no concatenes «de»):

| ca | dilluns, 20 d’octubre (*de* ante consonante, *d’* ante vocal: d’abril, d’agost, d’octubre) |
| gl | luns, 20 de outubro |
| eu | astelehena, urriaren 20a (mes + *-(r)en* + día + *-a*) |
| en | Monday, October 20 (US) · Monday, 20 October (UK). El orden depende de `en_GB` / `en_US`: el skeleton `MMMMEEEEd` lo resuelve solo. |

Hora: 24 h en todos los idiomas (también en inglés: `22:00`, es lo que ven los turnistas en Osakidetza/NHS). Evita AM/PM.

---

## 6. Tono por idioma

### Catalán
1. **Tuteo (*tu*)**, imperativo para botones y acciones: «Desa», «Cancel·la», «Esborra», «Torna-ho a provar». Es el patrón de Android/iOS en ca.
2. Punt volat en **«cancel·la»** (·), no `l.l`. Vigila las fuentes: el glifo `·` debe existir.
3. Apóstrofo tipográfico **’** en todos los textos (ver §7: el ASCII `'` rompe ICU).
4. Registro cercano pero correcto: *mòbil*, *calendari*, *torn*. Evita castellanismos (*quadrant* sí es catalán; *plus* solo en el sentido salarial).
5. Fuentes sectoriales: ICS, Mossos, Bombers, Generalitat; el catalán oficial es más formal (*vostè*) pero para una app de consumo se tutea.

### Gallego
1. **Tuteo (*ti*)**; botones en **infinitivo** (así lo hace Android/Xunta): «Gardar», «Cancelar», «Pechar», «Tentar de novo»; frases largas en imperativo de ti («Proba outra vez», «Escolle un patrón»).
2. Grafía RAG (normas 2003/2012): *xornada, quenda, vacacións, xoves, mércores, outubro, xuño*. Nada de *-ción* con *-cion* ni de *feriado*.
3. Contracciones obligatorias: *do, da, no, na, co, coa, polo, pola, ao*. No dejes «de o» / «en o».
4. **Confusión *mañá***: «turno de mañá» y «mañá (día siguiente)» se escriben igual; mantén «Mañá ({date})».
5. Uso real SERGAS: *garda, saínte, quenda, libre disposición*, no los sinónimos académicos más raros (*veceiro, rolda*, aunque el RAG los dé como sinónimos de *quenda*).

### Euskera
1. **Recomendación: *zu*, nunca *hi*.** *Hi* es íntimo, dialectal y obliga a **formas alocutivas con género** (*toka* masculino / *noka* femenino) que en una app serían imposibles de acertar con un único texto. *Zu* es el trato por defecto de Osakidetza, Eusko Jaurlaritza, Google, Apple y Microsoft en euskera, y suena ya cercano; el español «tú» de la app no exige *hi*. No se aplica registro alocutivo en ningún mensaje.
2. **Botones**: la forma de **raíz verbal / participio** (sin conjugar): «Gorde», «Utzi», «Ezabatu», «Itxi», «Berriro saiatu». Para frases: «Saiatu berriro», «Aukeratu txanda» (imperativo de zu = raíz verbal).
3. **Euskera estándar (batua), no dialecto.** Días y meses en minúscula (*astelehena*, *urria*), como en las normas de Euskaltzaindia **[C]**.
4. **Orden SOV**: el verbo va al final. No traduzcas palabra a palabra: «Termina en 3 h 40 min» → «**3 ordu eta 40 min barru** amaitzen da».
5. **Evita sufijos sobre variables** (`{time}etan`, `{name}rekin`, `{date}tik`): la forma depende de si el valor termina en vocal o consonante, de si es número y de cómo se pronuncia (20tik / 21etik / 22tik). Reordena para que la variable vaya sola tras dos puntos: «Hasiera: {time}», «Trukea: {name}», «Data: {date}».

### Inglés
1. **Neutral**: la app tiene selector de color, así que **hay que decidir una grafía**. Propuesta: US (*color*, *customize*), que es la de Flutter/Material; documentar la elección.
2. Sin diferencias de gramática, pero **vocabulario UK ↔ US** en sanidad: *rota/roster ↔ schedule*, *annual leave ↔ vacation*, *rest day ↔ day off*, *HCA ↔ CNA*, *porter ↔ orderly*, *overtime* igual, *night allowance ↔ night differential*, *Early/Late ↔ Day/Evening*.
3. Botones en **imperativo con inicial mayúscula solo de la primera palabra** (sentence case): «Save», «Try again», «Add shift». Sin punto final en botones.
4. «Hoy» = *Today*; «Hoy libre» = *Off today*; «Terminó a las {time}» = *Finished at {time}*; «Vuelves a las {time}» = *Back at {time}*.
5. Tuteo: *you*; evita *we* como «Nos hemos…» → «Couldn’t save the change.»

### Botones cortos (ancho limitado)

| es | ca | gl | eu | en |
|---|---|---|---|---|
| Guardar | Desa | Gardar | Gorde | Save |
| Cancelar | Cancel·la | Cancelar | Utzi | Cancel |
| Cerrar | Tanca | Pechar | Itxi | Close |
| Borrar | Esborra | Borrar | Ezabatu | Delete |
| Deshacer / Rehacer | Desfés / Refés | Desfacer / Refacer | Desegin / Berregin | Undo / Redo |
| Siguiente / Atrás | Següent / Enrere | Seguinte / Atrás | Hurrengoa / Atzera | Next / Back |
| Listo | Fet | Feito | Eginda | Done |
| Aplicar | Aplica | Aplicar | Aplikatu | Apply |
| Pintar | Pinta | Pintar | Margotu | Paint |
| Hoy | Avui | Hoxe | Gaur | Today |

---

## 7. Plurales ICU y trampas de gramática

### Comunes
- **Apóstrofo ICU**: en `intl`/ARB el `'` es carácter de escape. En ca y en usa siempre **’ (U+2019)**; si un texto necesita `'` real, se duplica (`''`).
- Revisa los `=0`, `=1` y `other`: ca/gl/en/eu solo tienen `one` y `other` en CLDR; `=0` y `=1` explícitos van bien.
- Cualquier mensaje con **concordancia de género** («Rotación eliminada», «Turno recuperado», «Patrón aplicado») cambia de forma según el sustantivo. No reutilices el mismo texto para turno (masc.) y rotación (fem.) en ca/gl.

### Catalán
- Artículos con elisión (*l’agenda*, *d’octubre*); preposición + artículo: *del, al, pel* ↔ *de l’, a l’* ante vocal. Por eso no pegues «de» o «el» a una variable; el `DateFormat` ya mete *de/d’*.
- Plural: `=1{1 dia copiat} other{{count} dies copiats}` (el sustantivo y el participio concuerdan).
- Participios femeninos: *una rotació eliminada*, *un torn recuperat*.

### Gallego
- Contracciones con variable: «Desde o {date}» (vale), pero «Do {name}» depende del género de {name}: evita construir *do/da* con variables.
- Plural: `=1{1 día copiado} other{{count} días copiados}`; femenino: *quenda recuperada / rotación eliminada*.
- Escribe *mañá* (con acento), nunca la forma castellana *mañana*.

### Euskera (lo más delicado)
- **Numerales + singular indeterminado**: «3 egun», «1 egun», «0 egun». El sustantivo **no** lleva marca de plural tras el número. El plural sólo aparece con determinante: *egunak* («los días»).
- **El verbo sí concuerda**: «Egun 1 aldatu da» (singular) vs. «**3 egun aldatu dira**» (plural). Por eso cada mensaje con verbo necesita `plural`:
  `{count, plural, =1{Egun 1 aldatu da} other{{count} egun aldatu dira}}`.
- **Ergativo**: si el sujeto es un agente de verbo transitivo hace falta *-k* y el verbo transitivo concuerda con objeto y agente (*du/ditu*). En Cuadrante casi todo es pasivo/absolutivo («se pegan N días» → «N egun itsatsi dira»), así que la mayoría de textos evitan ergativo; si aparece, pide revisión nativa.
- **Genitivo locativo -ko** con horas y lugares: *gaueko txanda* (turno de noche), *goizeko txanda*, *arratsaldeko txanda*. Con números o variables evita: en vez de «22:00ko txanda» usa «Txanda: 22:00–06:00». *Hurrengo txanda* («el siguiente turno») es correcto sin *-ko*.
- **Locativo -etan** («a las {time}») → no lo pongas sobre variable: «Amaiera: {time}». «Terminó a las 22:00» → «Amaitu da: 22:00».
- **Posposiciones de duración**: «dentro de {duration}» → «{duration} barru» (la variable queda sola).
- **Fechas con sufijo de día**: «urriaren 20a»; en rangos, los sufijos *-tik/-etik/-ra/-era* varían por número (20tik, 21etik, 22tik, 23tik…). Mejor «urriaren 20–25», o deja el rango al `DateFormat` / a una barra.
- **Artículo -a en meses y días de la semana**: «astelehena», «urtarrilaren 1a».
- **Orden SOV**: «Próximo: {name}, {weekday} {time}» → «Hurrengoa: {name}, {weekday} {time}».
- **Singular indefinido vs. definido en listas de contadores**: «Ez dago turnorik» («no hay turnos») usa partitivo *-rik* (*txandarik ez*): «Ez daukazu txandarik».
- **Siglas y números con declinación**: evita «TCAE-ra» etc.; si hace falta, reescribe («TCAE kategoria»).

### Inglés
- `=0{No days} =1{1 day} other{{count} days}`. Cuidado con «0 days» (se lee bien) y con «Day 1» si hay ordinales.
- Posesivos: *your shifts*; evita «'s» sobre variables.

---

## 8. Fuentes

**Verificadas en esta pasada** (el buscador las devolvió, con la lectura que se cita):
- Osakidetza, huelga por turnos: «GAUEKO txandan» / turnos de mañana y tarde — <https://www.euskadi.eus/eusko-jaurlaritza/-/albistea/2024/informazio-oharra-bizkaiko-emaginen-greba-deialdiaren-jarraipena-2024ko-uztailaren-1/> (txanda, gaueko txanda).
- Osakidetza, aparteko orduak / erizainak — <https://orain.eus/eu/aktualitatea/ekonomia/2024/06/10/elak-labek-eta-ccook-kritikatu-dute-osakidetzak-langile-falta-konpontzeko-egitasmorik-gabe-jarraitzen-duela/>.
- BOPV, «lan-txanda» y funciones de enfermería — <https://www.euskadi.eus/web01-bopv/eu/bopv2/datos/2022/11/2205085e.shtml>.
- Ertzaintza/RR. HH. de Seguridad, *lan-egutegiak* — <https://www.euskadi.eus/giza-baliabideen-zuzendaritza/segurtasuna/xiii/web01-a2langiz/eu> y <https://www.euskadi.eus/web01-bopv/eu/bopv2/datos/2025/11/2504936e.epub>.
- BFA (Diputación de Bizkaia) convenio de personal laboral, art. 65 «Norberaren arazoetarako lizentzia» — <https://mrafundazioa.eus/eu/dokumentazio-zentrua/propaganda/2018/2018-2019-bfa-ko-lan-kontratupekoen-hitzarmen-kolektiboa/@@download/file>.
- EHU / Euskaltzaindia, nombres de los meses — <https://www.ehu.eus/ehutsi/edukiak/informacion/ehutsi_610/eu_610/azalpenak.html>.
- RAG, *quenda* — <https://academia.gal/dicionario> (entrada «quenda»).
- Xunta, días de libre disposición del SERGAS — <https://www.xunta.gal/hemeroteca/-/nova/135426/sergas-organizacions-sindicais-abordan-caracteristicas-nova-categoria-facultativo> (contexto; menciona *días de libre disposición* en texto gallego).
- SERGAS, «Traballo a quendas» (medicina del trabajo) — <https://extranet.sergas.es/OPEWB/docs/gal/Personal/Doc/OPE/Cat3095/FEA_Medicina%20do%20Traballo_gal-20250721104801_gal.pdf>.
- Bombers de la Generalitat, *servei de guàrdia de 24 hores* / Mossos *torns de treball* — <https://naciodigital.cat/osona/societat/els-bombers-inicien-la-vaga-indefinida.html>, <https://www.3cat.cat/>.

**A consultar para cerrar los [C] y [P]** (no se pudieron abrir con las herramientas de esta pasada):
- Euskalterm: <https://www.euskadi.eus/euskalterm/> · Elhuyar: <https://hiztegiak.elhuyar.eus/> · Euskaltzaindia: <https://www.euskaltzaindia.eus/hiztegia> y las normas de calendario (EGLU / OEH).
- Termigal / TERMIGAL: <https://www.cirp.gal/termigal> (o la web de la Xunta) · Portal das Palabras: <https://academia.gal/portal-das-palabras>.
- TERMCAT / Cercaterm: <https://www.termcat.cat/ca/cercaterm> · DIEC2: <https://dlc.iec.cat/>.
- ICS: <https://ics.gencat.cat> · SERGAS: <https://www.sergas.gal> · Osakidetza: <https://www.osakidetza.eus> · Ertzaintza: <https://www.ertzaintza.eus>.
- CLDR (abreviaturas de días, meses): <https://cldr.unicode.org/> / paquete `intl` de Dart.

**Verificadas en la segunda pasada (23-oct, traducción de la app):**
- Osakidetza, *Erizaintzako Laguntzailea* (categoría del grupo Teknikari Laguntzaile Sanitarioak) — <https://www.euskadi.eus/web01-bopv/eu/bopv2/datos/2026/05/2602203e.shtml>.
- Osakidetza, *Zeladoreen Arduraduna* y *Goizeko lanaldia* (jornada de mañana) — <https://www.euskadi.eus/web01-bopv/eu/bopv2/datos/2022/01/2200097e.shtml>; categoría *zeladore* en un concurso de traslados — <https://www.euskadi.eus/bopv2/datos/2026/06/2602755e.pdf>.
- Sin resultado (siguen **[C]**/**[P]**): *guardia fisikoa / lokalizatua* y *norberaren gaietarako egunak* en Osakidetza; los buscadores no devolvieron ningún texto oficial con esas formas.

## 9. Pendientes para un hablante nativo

0. **Decisiones de la traducción (23-oct)**, a revisar con la persona nativa de cada idioma: en eu, códigos de plantilla `Goi/Arr/Gau/L/G24/GO/Opo/NE/E12/G12/Zat`, «Norberaren eguna» para libre disposición, «Egun 1» (cifra tras el sustantivo) en los plurales, fecha corta «urr 20, al» y «2026 urr 20»; en ca, «widget» (no *giny*) y «Torns rotatius» para correturnos; en gl, «widget» (no *trebello*) y «Quendas rotativas»; en en, *Off* (código O), *Post-night* (PN), *24-hour shift* (24), *Personal day* (PD), *Split* (S). Los nombres de los festivos siguen en español (vienen del paquete de datos): pendiente traducirlos o mostrarlos en la lengua cooficial de cada comunidad.
1. **eu**: *guardia* vs. *zaintza*; *Gau-ondokoa* (saliente); *txanden egutegia* (cuadrante); *txanda birakariak* (correturnos); *libre-eguna*; *jaiegun pertsonala*; denominación de *TCAE* y *celador* en Osakidetza; *norberaren arazoetarako/gaietarako egunak*.
2. **gl**: *cadro de quendas* (cuadrante); *widget* decidido (no *trebello*); M/M en la cabecera de lunes a domingo.
3. **ca**: *dia de descans* para libranza; gestión de TCAI; (*widget* decidido el 23-oct, como en gl y eu).
4. **en**: elegir ortografía (US/UK) y decidir entre *Morning/Afternoon/Night* y *Early/Late/Night*.
