/*
     María Arias Rodríguez, Jorge Ignacio Castañeda Vallenilla
     100522272@alumnos.uc3m.es, 100522273@alumnos.uc3m.es
*/
%{                          // SECCION 1 Declaraciones de C-Yacc

#include <stdio.h>
#include <ctype.h>            // declaraciones para tolower
#include <string.h>           // declaraciones para cadenas
#include <stdlib.h>           // declaraciones para exit ()

#define FF fflush(stdout);    // para forzar la impresion inmediata

int yylex () ;
int yyerror (char *s) ;
char *mi_malloc (int) ;
char *gen_code (char *) ;
char *int_to_string (int) ;
char *char_to_string (char) ;

char temp [2048] ;

// Abstract Syntax Tree (AST) Node Structure

typedef struct ASTnode t_node ;

struct ASTnode {
    char *op ;
    int type ;		// leaf, unary or binary nodes
    t_node *left ;
    t_node *right ;
} ;


// Definitions for explicit attributes

typedef struct s_attr {
    int value ;    // - Numeric value of a NUMBER 
    char *code ;   // - to pass IDENTIFIER names, and other translations 
    t_node *node ; // - for possible future use of AST
} t_attr ;

#define YYSTYPE t_attr

// Apartado de lógica añadida

char nombre_funcion_actual[256] = "";
char tabla_locales[100][256];
int n_locales = 0;

void limpiar_tabla_local() {
    n_locales = 0;
}

void insertar_local(char *id) {
    strcpy(tabla_locales[n_locales], id);
    n_locales++;
}

int es_local(char *id) {
    for (int i = 0; i < n_locales; i++) {
        if (strcmp(tabla_locales[i], id) == 0) return 1;
    }
    return 0;
}

char *resolver_identificador(char *id) { // Funcion que diferencia entre las variables locales y las globales
    char ltemp[2048];
    
    
    if (strlen(nombre_funcion_actual) > 0 && es_local(id)) {
        sprintf(ltemp, "%s_%s", nombre_funcion_actual, id);
    } else {
        sprintf(ltemp, "%s", id);
    }
    
    return gen_code(ltemp);
}

%}

// Definitions for explicit attributes

%token NUMBER        
%token IDENTIF       // Identificador=variable
%token INTEGER       // identifica el tipo entero
%token STRING
%token MAIN          // identifica el comienzo del proc. main
%token WHILE         // identifica el bucle main
%token PUTS
%token PRINTF
%token AND OR NOT
%token IGUAL_IGUAL DISTINTO MENOR_IGUAL MAYOR_IGUAL
%token IF ELSE
%token FOR INC DEC
%token SWITCH CASE DEFAULT BREAK
%token RETURN



%right '='           
%left OR                  
%left AND                       
%left IGUAL_IGUAL DISTINTO 
%left '<' '>' MENOR_IGUAL MAYOR_IGUAL 
%left '+' '-'             
%left '*' '/' '%'          
%right NOT UNARY_SIGN            

%%                            // Seccion 3 Gramatica - Semantico


// === AXIOMA ===
axioma:
    lista_globales lista_funciones_secundarias funcion_main { sprintf(temp, "%s\n%s\n%s", $1.code, $2.code, $3.code) ; $$.code = gen_code(temp) ; printf("%s\n", $$.code); }
;

// === DECLARACION DE VARIABLES GLOBALES ===
lista_globales:
    /*lambda*/                              { $$.code = gen_code("") ; }

    | lista_globales declaracion_global ';' { sprintf(temp, "%s\n%s", $1.code, $2.code); $$.code = gen_code(temp) ; }
;

declaracion_global:
    INTEGER lista_ids   { $$.code = $2.code ; }
;

lista_ids:
    identificador_individual                    { $$.code = $1.code ; }
    
    | lista_ids ',' identificador_individual    { sprintf(temp, "%s %s", $1.code, $3.code) ; $$.code = gen_code(temp) ; }
;

identificador_individual:
    IDENTIF                     { sprintf(temp, "(setq %s 0)", $1.code) ; $$.code = gen_code(temp) ; }

    | IDENTIF '=' NUMBER        { sprintf(temp, "(setq %s %d)", $1.code, $3.value) ; $$.code = gen_code(temp) ; }
    
    | IDENTIF '[' NUMBER ']'    { sprintf(temp, "(setq %s (make-array %d))", $1.code, $3.value) ; $$.code = gen_code(temp) ; }
;

// === DECLARACION DE VARIABLES LOCALES ===
declaracion_local:
    INTEGER lista_ids_locales   { $$.code = $2.code ; }
;

lista_ids_locales:
    identificador_local                         { $$.code = $1.code ; }

    | lista_ids_locales ',' identificador_local { sprintf(temp, "%s %s", $1.code, $3.code) ; $$.code = gen_code(temp) ; }
;

identificador_local:
      IDENTIF                   { insertar_local($1.code); sprintf(temp, "(setq %s_%s 0)", nombre_funcion_actual, $1.code) ; $$.code = gen_code(temp) ; }

    | IDENTIF '=' NUMBER        { insertar_local($1.code) ; sprintf(temp, "(setq %s_%s %d)", nombre_funcion_actual, $1.code, $3.value) ; $$.code = gen_code(temp) ; }

    | IDENTIF '[' NUMBER ']'    { insertar_local($1.code) ; sprintf(temp, "(setq %s_%s (make-array %d))", nombre_funcion_actual, $1.code, $3.value) ; $$.code = gen_code(temp) ; }
;

// === FUNCION MAIN ===
funcion_main:
      MAIN                              { strcpy(nombre_funcion_actual, "main") ; limpiar_tabla_local() ; } 
      '(' ')' '{' bloque_sentencias '}' { sprintf(temp, "(defun main ()\n%s)\n(main)", $6.code) ; $$.code = gen_code(temp) ; }
;

// === FUNCIONES SECUNDARIAS ===
lista_funciones_secundarias:
    /* lambda */                                        { $$.code = gen_code(""); }

    | lista_funciones_secundarias funcion_secundaria    { sprintf(temp, "%s\n%s", $1.code, $2.code) ; $$.code = gen_code(temp) ; }
;

funcion_secundaria:
    IDENTIF                                             { strcpy(nombre_funcion_actual, $1.code) ; limpiar_tabla_local(); }
    '(' lista_parametros ')' '{' bloque_sentencias '}'  { sprintf(temp, "(defun %s (%s)\n%s)", $1.code, $4.code, $7.code) ; $$.code = gen_code(temp) ; }
;

// === PARÁMETROS DE LAS FUNCIONES (DURANTE LA DEFINICION) ===
lista_parametros:
      /* lambda */          { $$.code = gen_code(""); }
    | lista_ids_parametros  { $$.code = $1.code; }
;

lista_ids_parametros:
      parametro                          { $$.code = $1.code; }
    | lista_ids_parametros ',' parametro { sprintf(temp, "%s %s", $1.code, $3.code) ; $$.code = gen_code(temp) ; }
;

parametro:
    INTEGER IDENTIF { insertar_local($2.code) ; sprintf(temp, "%s_%s", nombre_funcion_actual, $2.code) ; $$.code = gen_code(temp) ; }
;

// === GESTION DE ARGUMENTOS (LLAMADAS A LAS FUNCIONES) ===
lista_argumentos:
    /* lambda */        { $$.code = gen_code("") ; }

    | lista_expresiones { $$.code = $1.code ; }
;

lista_expresiones:
    expresion                           { $$.code = $1.code; }

    | lista_expresiones ',' expresion   { sprintf(temp, "%s %s", $1.code, $3.code) ; $$.code = gen_code(temp) ; }
;
    
// === CUERPO DE LAS FUNCIONES ===
bloque_sentencias:
            /*lambda*/                      { $$.code = gen_code("") ; }

            | bloque_sentencias sentencia   { sprintf(temp, "%s %s\n", $1.code, $2.code) ; $$.code = gen_code(temp) ; }
;

sentencia:
    sentencia_normal ';'    { $$.code = $1.code ; }

    | estructuras_control   { $$.code = $1.code ; }
;

// === SENTENCIAS NORMALES ===
sentencia_normal:
    IDENTIF '=' expresion                       { sprintf(temp, "(setf %s %s)", resolver_identificador($1.code), $3.code) ; $$.code = gen_code(temp) ; }
    
    | IDENTIF '[' expresion ']' '=' expresion   { sprintf(temp, "(setf (aref %s %s) %s)", resolver_identificador($1.code), $3.code, $6.code) ; $$.code = gen_code(temp) ; }
    
    | declaracion_local                         { $$.code = $1.code ; }

    | PUTS '(' STRING ')'                       { sprintf(temp, "(print \"%s\")", $3.code) ; $$.code = gen_code(temp) ; }

    | PRINTF '(' STRING ',' lista_elems ')'     { $$.code = $5.code; }

    | IDENTIF '(' lista_argumentos ')'          { sprintf(temp, "(%s %s)", $1.code, $3.code) ; $$.code = gen_code(temp); }

    | RETURN expresion                          { sprintf(temp, "(return-from %s %s)", nombre_funcion_actual, $2.code) ; $$.code = gen_code(temp) ; }
;

lista_elems:
    elem                    { sprintf(temp, "(princ %s)", $1.code) ; $$.code = gen_code(temp); }

    | lista_elems ',' elem  { sprintf(temp, "%s (princ %s)", $1.code, $3.code) ; $$.code = gen_code(temp) ; }
;

elem:
    expresion   { $$.code = $1.code; }

    | STRING    { $$.code = $1.code; }
;

// === ESTRUCTURAS DE CONTROL ===
estructuras_control:
    WHILE '(' expresion ')' '{' bloque_sentencias '}'           { sprintf(temp, "(loop while %s do (progn %s))", $3.code, $6.code); $$.code = gen_code(temp) ; }

    | IF '(' expresion ')' '{' bloque_sentencias '}' resto_else { sprintf(temp, "(if %s (progn %s)%s)", $3.code, $6.code, $8.code) ; $$.code = gen_code(temp); }

    | FOR '(' asignacion_for ';' expresion ';' modificacion_for ')' '{' bloque_sentencias '}'
                                                                { sprintf(temp, "%s\n(loop while %s do (progn %s %s))", $3.code, $5.code, $10.code, $7.code); $$.code = gen_code(temp) ; }

    | SWITCH '(' IDENTIF ')' '{' casos_switch '}'               { sprintf(temp, "(case %s %s)", resolver_identificador($3.code), $6.code) ; $$.code = gen_code(temp) ; }
;

resto_else:
    /* lambda */                        { sprintf(temp, "") ; $$.code = gen_code(temp) ; }

    | ELSE '{' bloque_sentencias '}'    { sprintf(temp, " (progn %s)", $3.code) ; $$.code = gen_code(temp) ; }
;

asignacion_for:
    IDENTIF '=' expresion { sprintf(temp, "(setf %s %s)", resolver_identificador($1.code), $3.code); $$.code = gen_code(temp) ; }
;

modificacion_for:
    INC '(' IDENTIF ')'     { char *id = resolver_identificador($3.code) ; sprintf(temp, "(setf %s (+ %s 1))", id, id) ; $$.code = gen_code(temp) ; }
    
    | DEC '(' IDENTIF ')'   { char *id = resolver_identificador($3.code) ; sprintf(temp, "(setf %s (- %s 1))", id, id); $$.code = gen_code(temp) ; }
;

casos_switch:
    lista_casos                                             { $$.code = $1.code; }
    
    | lista_casos DEFAULT ':' bloque_sentencias BREAK ';'   { sprintf(temp, "%s (otherwise (progn %s))", $1.code, $4.code) ; $$.code = gen_code(temp) ; }
;

lista_casos:
    /* lambda */                                                { $$.code = gen_code("") ; }
    
    | lista_casos CASE NUMBER ':' bloque_sentencias BREAK ';'   { sprintf(temp, "%s (%d (progn %s))", $1.code, $3.value, $5.code); $$.code = gen_code(temp) ; }
;

// === ARITMÉTICA ===
expresion:
    termino                             { $$ = $1 ; }

    |   expresion '+' expresion         { sprintf (temp, "(+ %s %s)", $1.code, $3.code) ; $$.code = gen_code (temp) ; }

    |   expresion '-' expresion         { sprintf (temp, "(- %s %s)", $1.code, $3.code) ; $$.code = gen_code (temp) ; }

    |   expresion '*' expresion         { sprintf (temp, "(* %s %s)", $1.code, $3.code) ; $$.code = gen_code (temp) ; }

    |   expresion '/' expresion         { sprintf (temp, "(/ %s %s)", $1.code, $3.code) ; $$.code = gen_code (temp) ; }

    |   expresion AND expresion         { sprintf(temp, "(and %s %s)", $1.code, $3.code); $$.code = gen_code(temp); }

    |   expresion OR  expresion         { sprintf(temp, "(or %s %s)", $1.code, $3.code); $$.code = gen_code(temp); }

    |   NOT expresion                   { sprintf(temp, "(not %s)", $2.code) ; $$.code = gen_code(temp); }

    |   expresion IGUAL_IGUAL expresion { sprintf(temp, "(= %s %s)", $1.code, $3.code); $$.code = gen_code(temp); }

    |   expresion DISTINTO expresion    { sprintf(temp, "(/= %s %s)", $1.code, $3.code); $$.code = gen_code(temp); }

    |   expresion '<' expresion         { sprintf(temp, "(< %s %s)", $1.code, $3.code); $$.code = gen_code(temp); }

    |   expresion '>' expresion         { sprintf(temp, "(> %s %s)", $1.code, $3.code); $$.code = gen_code(temp); }

    |   expresion MENOR_IGUAL expresion { sprintf(temp, "(<= %s %s)", $1.code, $3.code); $$.code = gen_code(temp); }

    |   expresion MAYOR_IGUAL expresion { sprintf(temp, "(>= %s %s)", $1.code, $3.code); $$.code = gen_code(temp); }

    |   expresion '%' expresion         { sprintf(temp, "(mod %s %s)", $1.code, $3.code); $$.code = gen_code(temp); }
;

termino:
    operando                        { $$ = $1 ; }

    | '+' operando %prec UNARY_SIGN { $$ = $1 ; }

    | '-' operando %prec UNARY_SIGN { sprintf (temp, "(- %s)", $2.code) ; $$.code = gen_code (temp) ; }    
;

operando:
    IDENTIF                             { $$.code = resolver_identificador($1.code) ; }
        
    | NUMBER                            { sprintf (temp, "%d", $1.value) ; $$.code = gen_code (temp) ; }

    | IDENTIF '[' expresion ']'         { sprintf(temp, "(aref %s %s)", resolver_identificador($1.code), $3.code) ; $$.code = gen_code(temp); }
        
    | '(' expresion ')'                 { $$ = $2 ; }

    | IDENTIF '(' lista_argumentos ')'  { sprintf(temp, "(%s %s)", $1.code, $3.code) ; $$.code = gen_code(temp) ; }
;

%%                            // SECCION 4    Codigo en C

int n_line = 1 ;

int yyerror (char *mensaje)
{
    fprintf (stderr, "Error: %s en la linea %d\n", mensaje, n_line);
    return 0;
}

char *int_to_string (int n)
{
    char ltemp [2048] ;

    sprintf (ltemp, "%d", n) ;

    return gen_code (ltemp) ;
}

char *char_to_string (char c)
{
    char ltemp [2048] ;

    sprintf (ltemp, "%c", c) ;

    return gen_code (ltemp) ;
}

char *my_malloc (int nbytes)       // reserva n bytes de memoria dinamica
{
    char *p ;
    static long int nb = 0;        // sirven para contabilizar la memoria
    static int nv = 0 ;            // solicitada en total

    p = malloc (nbytes) ;
    if (p == NULL) {
        fprintf (stderr, "No queda memoria para %d bytes mas\n", nbytes) ;
        fprintf (stderr, "Reservados %ld bytes en %d llamadas\n", nb, nv) ;
        exit (0) ;
    }
    nb += (long) nbytes ;
    nv++ ;

    return p ;
}


/***************************************************************************/
/********************** Seccion de Palabras Reservadas *********************/
/***************************************************************************/

typedef struct s_keyword { // para las palabras reservadas de C
    char *name ;
    int token ;
} t_keyword ;

t_keyword keywords [] = { // define las palabras reservadas y los
    "main",        MAIN,           // y los token asociados
    "int",         INTEGER,
    "puts",        PUTS,
    "printf",      PRINTF,
    "&&",   AND,
    "||",   OR,
    "!",    NOT,
    "!=",   DISTINTO,
    "==",   IGUAL_IGUAL,
    "<=",   MENOR_IGUAL,
    ">=",   MAYOR_IGUAL,
    "while",   WHILE,
    "if",    IF,
    "else",  ELSE,
    "for",     FOR,
    "inc",     INC,
    "dec",     DEC,
    "switch",   SWITCH,    
    "case",     CASE,
    "default",  DEFAULT,
    "break",    BREAK,
    "return",   RETURN,
    NULL,          0               // para marcar el fin de la tabla
} ;

t_keyword *search_keyword (char *symbol_name)
{                                  // Busca n_s en la tabla de pal. res.
                                   // y devuelve puntero a registro (simbolo)
    int i ;
    t_keyword *sim ;

    i = 0 ;
    sim = keywords ;
    while (sim [i].name != NULL) {
	    if (strcmp (sim [i].name, symbol_name) == 0) {
		                             // strcmp(a, b) devuelve == 0 si a==b
            return &(sim [i]) ;
        }
        i++ ;
    }

    return NULL ;
}

 
/***************************************************************************/
/******************* Seccion del Analizador Lexicografico ******************/
/***************************************************************************/

char *gen_code (char *name)     // copia el argumento a un
{                                      // string en memoria dinamica
    char *p ;
    int l ;
	
    l = strlen (name)+1 ;
    p = (char *) my_malloc (l) ;
    strcpy (p, name) ;
	
    return p ;
}


int yylex () {
// NO MODIFICAR ESTA FUNCION SIN PERMISO
    int i ;
    unsigned char c ;
    unsigned char cc ;
    char ops_expandibles [] = "!<=|>%&/+-*" ;
    char temp_str [256] ;
    t_keyword *symbol ;

    do {
        c = getchar () ;

        if (c == '#') {	// Ignora las lineas que empiezan por #  (#define, #include)
            do {		//	OJO que puede funcionar mal si una linea contiene #
                c = getchar () ;
            } while (c != '\n') ;
        }

        if (c == '/') {	// Si la linea contiene un / puede ser inicio de comentario
            cc = getchar () ;
            if (cc != '/') {   // Si el siguiente char es /  es un comentario, pero...
                ungetc (cc, stdin) ;
            } else {
                c = getchar () ;	// ...
                if (c == '@') {	// Si es la secuencia //@  ==> transcribimos la linea
                    do {		// Se trata de codigo inline (Codigo embebido en C)
                        c = getchar () ;
                        putchar (c) ;
                    } while (c != '\n') ;
                } else {		// ==> comentario, ignorar la linea
                    while (c != '\n') {
                        c = getchar () ;
                    }
                }
            }
        } else if (c == '\\') c = getchar () ;
		
        if (c == '\n')
            n_line++ ;

    } while (c == ' ' || c == '\n' || c == 10 || c == 13 || c == '\t') ;

    if (c == '\"') {
        i = 0 ;
        do {
            c = getchar () ;
            temp_str [i++] = c ;
        } while (c != '\"' && i < 255) ;
        if (i == 256) {
            printf ("AVISO: string con mas de 255 caracteres en linea %d\n", n_line) ;
        }		 	// habria que leer hasta el siguiente " , pero, y si falta?
        temp_str [--i] = '\0' ;
        yylval.code = gen_code (temp_str) ;
        return (STRING) ;
    }

    if (c == '.' || (c >= '0' && c <= '9')) {
        ungetc (c, stdin) ;
        scanf ("%d", &yylval.value) ;
//         printf ("\nDEV: NUMBER %d\n", yylval.value) ;        // PARA DEPURAR
        return NUMBER ;
    }

    if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')) {
        i = 0 ;
        while (((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') ||
            (c >= '0' && c <= '9') || c == '_') && i < 255) {
            temp_str [i++] = tolower (c) ;
            c = getchar () ;
        }
        temp_str [i] = '\0' ;
        ungetc (c, stdin) ;

        yylval.code = gen_code (temp_str) ;
        symbol = search_keyword (yylval.code) ;
        if (symbol == NULL) {    // no es palabra reservada -> identificador antes vrariabre
//               printf ("\nDEV: IDENTIF %s\n", yylval.code) ;    // PARA DEPURAR
            return (IDENTIF) ;
        } else {
//               printf ("\nDEV: OTRO %s\n", yylval.code) ;       // PARA DEPURAR
            return (symbol->token) ;
        }
    }

    if (strchr (ops_expandibles, c) != NULL) { // busca c en ops_expandibles
        cc = getchar () ;
        sprintf (temp_str, "%c%c", (char) c, (char) cc) ;
        symbol = search_keyword (temp_str) ;
        if (symbol == NULL) {
            ungetc (cc, stdin) ;
            yylval.code = NULL ;
            return (c) ;
        } else {
            yylval.code = gen_code (temp_str) ; // aunque no se use
            return (symbol->token) ;
        }
    }

//    printf ("\nDEV: LITERAL %d #%c#\n", (int) c, c) ;      // PARA DEPURAR
    if (c == EOF || c == 255 || c == 26) {
//         printf ("tEOF ") ;                                // PARA DEPURAR
        return (0) ;
    }

    return c ;
}


int main ()
{
    yyparse () ;
}
