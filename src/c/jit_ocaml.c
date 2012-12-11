#include <stdlib.h>
#include <stdio.h>

#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/callback.h>
#include <stdlib.h>
#include "jit_ocaml.h"

extern void caml_startup(char** argv);

static value jit_ocaml_registered_callback = Val_unit;

value jit_ocaml_register_callback_c(value callback)
{
  jit_ocaml_registered_callback = callback;
  caml_register_global_root(&jit_ocaml_registered_callback);
  return Val_unit;
}

char* jit_ocaml_analyze(char *buf)
{
  value ret;

  if( jit_ocaml_registered_callback == Val_unit ){
    char *argv[1];
    argv[0] = NULL;
    caml_startup(argv);
  }
  fprintf(stderr, "%d %d %d %d\n", buf[0],buf[1],buf[2],buf[3]);
  ret = caml_callback(jit_ocaml_registered_callback, (value)buf);
  return buf;
}
