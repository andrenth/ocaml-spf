# OCaml-SPF

## Introduction

This library provides OCaml bindings to [libspf2](http://www.libspf2.org/).

## Build and installation

After cloning the repository, run the commands below to build OCaml-Milter.

    $ ocaml setup.ml -configure
    $ ocaml setup.ml -build

Documentation can be generated with the command below.

    $ ocaml setup.ml -doc

To install OCaml-SPF, run

    # ocaml setup.ml -install

## Notes

It is strongly recommended that a [patched libspf2 with fixes collected from
the SPF-devel mailing list](https://github.com/andrenth/libspf2) is used
instead of the current official libspf2 release (version 1.2.9).
