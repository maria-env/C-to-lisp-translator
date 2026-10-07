# C-like Language to Lisp Translator
 
Source-to-source translator built with Bison (LALR grammar) that converts programs written in a subset of C into Lisp code. Final project for the Programming Language Processors course (Universidad Carlos III de Madrid).
 
## Supported features
 
- Global and local variables, with scope resolved at translation time (a local variable `i` in `main` is translated as `main_i`).
- Functions with parameters and `return`, plus the `main` function.
- Control structures: `if`/`else`, `while`, `for` and `switch`/`case`/`default`.
- Arrays (declaration, indexed read and write).
- Output with `puts` and `printf`.
## Files
 
- `trad2.y`: grammar with the lexical analyzer and code generation.
## Technologies
 
C · Bison
 
## Build and usage
 
```bash
bison trad2.y
gcc trad2.tab.c -o trad2
./trad2 < program.c > program.lisp
```
 
The program reads the source code from standard input (with symbols separated by spaces) and writes the resulting Lisp to standard output. For example:
 
```
sum ( int a , int b ) { return a + b ; }
main ( ) {
    int v [ 3 ] ; int x ;
    v [ 0 ] = 10 ;
    x = sum ( v [ 0 ] , 5 ) ;
    switch ( x ) { case 15 : puts ( "fifteen" ) ; break ; default : puts ( "other" ) ; break ; }
}
```
 
## Authors
 
Team project by María Arias Rodríguez and Jorge Ignacio Castañeda Vallenilla.
