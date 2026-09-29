# Compilador de un lenguaje tipo C a Lisp

Traductor fuente a fuente construido con Bison (gramática LALR) que convierte programas escritos en un subconjunto de C a código Lisp. Práctica final de Procesadores del Lenguaje (Universidad Carlos III de Madrid).

## Qué soporta

- Variables globales y locales, con el ámbito resuelto en la traducción (una variable local `i` de `main` se traduce como `main_i`).
- Funciones con parámetros y `return`, y la función `main`.
- Estructuras de control: `if`/`else`, `while`, `for` y `switch`/`case`/`default`.
- Arrays (declaración, lectura y escritura con índice).
- Salida con `puts` y `printf`.

## Archivos

- `trad2.y`: gramática con el analizador léxico y la generación de código.

## Tecnologías

C · Bison

## Cómo compilarlo y usarlo

```bash
bison trad2.y
gcc trad2.tab.c -o trad2
./trad2 < programa.c > programa.lisp
```

El programa lee el código fuente por la entrada estándar (con los símbolos separados por espacios) y escribe el Lisp resultante por la salida estándar. Por ejemplo:

```
suma ( int a , int b ) { return a + b ; }
main ( ) {
    int v [ 3 ] ; int x ;
    v [ 0 ] = 10 ;
    x = suma ( v [ 0 ] , 5 ) ;
    switch ( x ) { case 15 : puts ( "quince" ) ; break ; default : puts ( "otro" ) ; break ; }
}
```

## Autoría

Trabajo en equipo de María Arias Rodríguez y Jorge Castañeda.
