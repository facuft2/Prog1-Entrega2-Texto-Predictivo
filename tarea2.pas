// Función hash. Retorna el código de la función de hash que describimos en
// la tarea 1 para la palabra p usando los parámetros semilla, paso y N.
function hash ( semilla, paso, N : Natural; p : Palabra ) : Natural;
var
  i : Integer;
  hashResult : Natural;
begin
    hashResult := semilla;
    for i := 1 to p.tope do
        hashResult := ( hashResult * paso + ord( p.cadena[i] ) ) mod N;
    hash := hashResult;
    end;

// Función comparaPalabra. Retorna el resultado de comparar la palabras
// p1 y p2 en base al orden lexicográfico. Si p1 es menor que p2 retorna
// menor, si es mayor retorna mayor y si son iguales retorna igual.

function comparaPalabra ( p1, p2 : Palabra ) : Comparacion;
var
    i : Natural;
begin
    i := 1;
    while ( i <= p1.tope ) and ( i <= p2.tope ) and ( p1.cadena[i] = p2.cadena[i] ) do
        i := i + 1;
    if ( i > p1.tope ) and ( i > p2.tope ) then
        comparaPalabra := igual
    else if ( i > p1.tope ) or ( ( i <= p2.tope ) and ( p1.cadena[i] < p2.cadena[i] ) ) then
        comparaPalabra := menor
    else
        comparaPalabra := mayor;
    end;


// Función mayorPalabraCant. Retorna true si la cantidad de ocurrencias
// de pc1 es mayor que la de pc2 o si son iguales y la palabra de pc1 es mayor
// (en orden lexicográfico) que la de pc2. En otro caso retorna false.
function mayorPalabraCant( pc1, pc2 : PalabraCant ) : boolean;
begin
    if pc1.cant > pc2.cant then
        mayorPalabraCant := true
    else if pc1.cant < pc2.cant then
        mayorPalabraCant := false
    else
        mayorPalabraCant := comparaPalabra( pc1.pal, pc2.pal ) = mayor;
    end;

// Procedimiento agregarOcurrencia. Agrega una ocurrencia de la palabra
// p en la lista de ocurrencias pals. Si la palabra ya pertenece a pals
// entonces incrementa la cantidad de ocurrencias. Si la palabra no pertenece,
// se inserta al final de la lista (con cantidad 1).
procedure agregarOcurrencia ( p : Palabra; var pals: Ocurrencias );
var
    actual, anterior : Ocurrencias;
begin
    actual := pals;
    anterior := nil;
    while ( actual <> nil ) and ( comparaPalabra( actual^.palc.pal, p ) <> igual ) do
    begin
        anterior := actual;
        actual := actual^.sig;
    end;
    if actual = nil then
    begin
        new( actual );
        actual^.palc.pal := p;
        actual^.palc.cant := 1;
        actual^.sig := nil;
        if anterior = nil then
            pals := actual
        else
            anterior^.sig := actual;
    end
    else
        actual^.palc.cant := actual^.palc.cant + 1;
    end;
    

// Procedimiento inicializarPredictor. Inicializa el predictor pred dejando vacías todas las listas de ocurrencias.
procedure inicializarPredictor ( var pred: Predictor );
var
    i : Integer;
begin
    for i := 1 to MAXHASH - 1 do pred[i] := nil;
end;

// Procedimiento entrenarPredictor. Dada una lista de palabras txt que
// representa a un texto, entrena al predictor pred con dicho texto. Esto
// es: para cada par de palabras palabra1 palabra2 que aparece en el texto
// se agrega al lugar del arreglo pred indexado por el código de hash de
// palabra1 una ocurrencia de palabra2. Para agregar la ocurrencia se utiliza
// el procedimiento agregarOcurrencia. El entrenamiento es acumulativo,
// esto es que si pred ya tenía datos de entrenamientos anteriores, se deben
// mantener.
// Palabra	= record
// 		     cadena : array [1 .. MAXPAL] of Letra;
// 		     tope   : 0 .. MAXPAL
// 		  end;

//    { enumerado para indicar el resultado de una comparación entre palabras }
//    Comparacion	= (menor, igual, mayor);

//    { lista de palabras, que representa a un texto }
//    Texto	= ^NodoPal; 
//    NodoPal	= record  
// 		     info : Palabra;
// 		     sig  : Texto
// 		  end;
procedure entrenarPredictor ( txt : Texto; var pred: Predictor );
var
    i : Integer;
begin
    while txt <> nil do
    begin
        i := 1;
        while i < txt^.info.tope do
        begin
            agregarOcurrencia( txt^.info, pred[hash( SEMILLA, PASO, MAXHASH, txt^.info )] );
            i := i + 1; 
        end;
        txt := txt^.sig;
    end;
    end;

// Procedimiento insOrdAlternativas. Inserta pc en alts conservando su
// orden, que es de mayor a menor de acuerdo a la relación de orden definida
// en mayorPalabraCant. Se puede considerar que no hay palabras repetidas.
// Si alts tiene MAXALTS elementos y todos son mayores que pc, entonces éste
// no se inserta. Para implementar este procedimiento se sugiere el siguiente
// algoritmo: insertar pc al final de alts (si es posible) y luego intercambiarlo
// con los elementos a su izquierda hasta que llegue a la posición que le
// corresponde.
procedure insOrdAlternativas ( pc : PalabraCant; var alts: Alternativas );
var
    i : Natural;
    aux : PalabraCant;
begin
    if alts.tope < MAXALTS then
    begin
        alts.tope := alts.tope + 1;
        alts.pals[alts.tope] := pc;
        i := alts.tope;
        while ( i > 1 ) and mayorPalabraCant( alts.pals[i], alts.pals[i - 1] ) do
        begin
            aux := alts.pals[i];
            alts.pals[i] := alts.pals[i - 1];
            alts.pals[i - 1] := aux;
            i := i - 1;
        end;
    end
    else if mayorPalabraCant( pc, alts.pals[MAXALTS] ) then
    begin
        alts.pals[MAXALTS] := pc;
        i := MAXALTS;
        while ( i > 1 ) and mayorPalabraCant( alts.pals[i], alts.pals[i - 1] ) do
        begin
            aux := alts.pals[i];
            alts.pals[i] := alts.pals[i - 1];
            alts.pals[i - 1] := aux;
            i := i - 1;
        end;
    end;
    end;

// Procedimiento obtenerAlternativas. Retorna en alts hasta MAXALTS
// alternativas de palabras que pueden ir a continuación de p de acuerdo a la
// información de ocurrencias que contiene pred. Este procedimiento utiliza
// insOrdAlternativas para insertar las palabras en alts ordenadas según
// el número de ocurrencias.
procedure obtenerAlternativas ( p : Palabra; pred : Predictor; var alts: Alternativas );
var
    actual : Ocurrencias;
begin
    alts.tope := 0;
    actual := pred[hash( SEMILLA, PASO, MAXHASH, p )];
    while ( actual <> nil ) do
    begin
        insOrdAlternativas( actual^.palc, alts );
        actual := actual^.sig;
    end;
    end;