# minilisp
A small lisp interpreter with reference counting memory management aimed at interactive games development

## Building

Run
```
make
```
## Running

Run
```
./lisp
```

The application reads input from stdin.
To close the interpreter press Ctrl-D or enter (quit).

## Running examples

Some examples load dynamic libraries (GLFW, SDL2 etc.) which need to be preinstalled.

Run
```
./lisp drive.lisp
```
or choose a different filename.
