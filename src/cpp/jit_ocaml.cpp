/*
 *  Scilab ( http://www.scilab.org/ ) - This file is part of Scilab
 *  Copyright (C) 2010-2010 - DIGITEO - Antoine ELIAS
 *
 *  This file must be used under the terms of the CeCILL.
 *  This source file is licensed as described in the file COPYING, which
 *  you should have received as part of this distribution.  The terms
 *  are also available at
 *  http://www.cecill.info/licences/Licence_CeCILL_V2-en.txt
 *
 */

#ifndef AST_RUNVISITOR_HXX
#define AST_RUNVISITOR_HXX

#include "jit_ocaml.hxx"

ast::Exp* jit_ocaml(ast::Exp* ast0)
{
  std::cerr << "jit_ocaml !!!" << std::endl;
  return ast0;
}

#endif // !AST_RUNVISITOR_HXX
