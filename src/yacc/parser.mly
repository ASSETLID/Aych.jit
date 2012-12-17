%{
  open ScilabAst
  open Lexing

  let create_loc start_pos end_pos =
    { first_line = start_pos.pos_lnum; 
      first_column = (start_pos.pos_cnum - start_pos.pos_bol); 
      last_line = end_pos.pos_lnum;
      last_column = (end_pos.pos_cnum - end_pos.pos_bol) }

  let create_exp loc desc =
    let infos = 
      { is_verbose = false;
        is_break = false;
        is_breakable = false;
        is_return = false;
        is_returnable = false;
        is_continue = false;
        is_continuable  = false} in
    {exp_location = loc; exp_desc = desc; exp_info = infos}
      

%}

%token LBRACK RBRACK LPAREN RPAREN LBRACE RBRACE DOLLAR SPACES
%token COMMA EOL DOLLAR SEMI IF THEN ELSE ELSEIF END WHILE DO 
%token COLON ASSIGN ID FOR
%token BOOLTRUE BOOLFALSE
%token<float> VARINT
%token<float> VARFLOAT
%token<float> NUM
%token<string> ID
%token<string> COMMENT
%token EOF

%nonassoc TOPLEVEL
%nonassoc HIGHLEVEL
%nonassoc UPLEVEL
%nonassoc LISTABLE

%nonassoc CONTROLBREAK

%left OR OROR
%left AND ANDAND

%left COLON
%left EQ NE LT LE GT GE
%left MINUS PLUS
%left TIMES DOTTIMES KRONTIMES CONTROLTIMES RDIVIDE DOTRDIVIDE KRONRDIVIDE CONTROLRDIVIDE LDIVIDE DOTLDIVIDE KRONLDIVIDE CONTROLLDIVIDE
%left POWER DOTPOWER

%left QUOTE DOTQUOTE

%left DOT

%left NOT

%nonassoc FUNCTIONCALL
%nonassoc BOOLTRUE BOOLFALSE
%nonassoc LPAREN LBRACE


%start program
%type <ScilabAst.ast>program

%%
program :
| expressions                                   { $1 }
| expressions EOF                               { $1 }

expressions :
| expression                                    { let seqexp = SeqExp [$1] in
                                                  let off_st = Parsing.rhs_start_pos 1 in
                                                  let off_end = Parsing.rhs_end_pos 1 in
                                                  let loc = create_loc off_st off_end in
                                                  Exp (create_exp loc seqexp) }
| expression COMMENT                           { let commentexp = CommentExp { commentExp_comment = $2 } in
                                                 let cmt_st = Parsing.rhs_start_pos 2 in
                                                 let cmt_end = Parsing.rhs_end_pos 2 in
                                                 let cmt_loc = create_loc cmt_st cmt_end in
                                                 let cmt_exp = create_exp cmt_loc (ConstExp commentexp) in
                                                 let seqexp = SeqExp ($1::[cmt_exp]) in
                                                 let off_st = Parsing.rhs_start_pos 1 in
                                                 let off_end = Parsing.rhs_end_pos 2 in
                                                 let loc = create_loc off_st off_end in
                                                 Exp (create_exp loc seqexp) }

expression :
| functionCall                                  { $1 }
| variableDeclaration                           { $1 }
| ifControl                                     { $1 }
| forControl                                    { $1 }
| whileControl                                  { $1 }
| variable                                      { $1 }
| COMMENT                                       { let commentexp = CommentExp { commentExp_comment = $1 } in
                                                  let off_st = Parsing.rhs_start_pos 1 in
                                                  let off_end = Parsing.rhs_end_pos 1 in
                                                  let loc = create_loc off_st off_end in
                                                  create_exp loc (ConstExp commentexp)
                                                }

/* FUNCTIONCALL */
functionCall :
| simpleFunctionCall                            { $1 }
| specificFunctionCall                          { $1 } 
| LPAREN functionCall RPAREN                    { $2 }

specificFunctionCall :
| BOOLTRUE LPAREN functionArgs RPAREN           { let varloc_st = Parsing.rhs_start_pos 1 in
                                                  let varloc_end = Parsing.rhs_end_pos 1 in
                                                  let varloc = create_loc varloc_st varloc_end in
                                                  let varexp = 
                                                    Var { var_location = varloc;
                                                          var_desc = SimpleVar "%t" } in
                                                  let callexp = 
                                                    { callExp_name = create_exp varloc varexp;
                                                      callExp_args = Array.of_list $3} in
                                                  let fcall_st = Parsing.rhs_start_pos 1 in
                                                  let fcall_end = Parsing.rhs_end_pos 4 in
                                                  let loc = create_loc fcall_st fcall_end in
                                                  create_exp loc (CallExp callexp) }
| BOOLFALSE LPAREN functionArgs RPAREN          { let varloc_st = Parsing.rhs_start_pos 1 in
                                                  let varloc_end = Parsing.rhs_end_pos 1 in
                                                  let varloc = create_loc varloc_st varloc_end in
                                                  let varexp = 
                                                    Var { var_location = varloc;
                                                          var_desc = SimpleVar "%f" } in
                                                  let callexp = 
                                                    { callExp_name = create_exp varloc varexp;
                                                      callExp_args = Array.of_list $3} in
                                                  let fcall_st = Parsing.rhs_start_pos 1 in
                                                  let fcall_end = Parsing.rhs_end_pos 4 in
                                                  let loc = create_loc fcall_st fcall_end in
                                                  create_exp loc (CallExp callexp) }

simpleFunctionCall :
| ID LPAREN functionArgs RPAREN                 { let varloc_st = Parsing.rhs_start_pos 1 in
                                                  let varloc_end = Parsing.rhs_end_pos 1 in
                                                  let varloc = create_loc varloc_st varloc_end in
                                                  let varexp = 
                                                    Var { var_location = varloc;
                                                          var_desc = SimpleVar $1 } in
                                                  let callexp = 
                                                    { callExp_name = create_exp varloc varexp;
                                                      callExp_args = Array.of_list $3} in
                                                  let fcall_st = Parsing.rhs_start_pos 1 in
                                                  let fcall_end = Parsing.rhs_end_pos 4 in
                                                  let loc = create_loc fcall_st fcall_end in
                                                  create_exp loc (CallExp callexp) }
/*| ID LBRACE functionArgs RPAREN */

functionArgs :
| variable                                      { [$1] }
| functionCall                                  { [$1] }
| COLON                                         { let cvarloc_st = Parsing.rhs_start_pos 1 in
                                                  let cvarloc_end = Parsing.rhs_end_pos 1 in
                                                  let loc = create_loc cvarloc_st cvarloc_end in
                                                  let cvar_exp = 
                                                    Var { var_location = loc;
                                                          var_desc = ColonVar } in 
                                                  [ create_exp loc cvar_exp ]}
| variableDeclaration                           { [$1] }
| /* Empty */                                   { [] }
| functionArgs COMMA variable                   { $3::$1 }
| functionArgs COMMA functionCall               { $3::$1 }
| functionArgs COMMA COLON                      { let cvarloc_st = Parsing.rhs_start_pos 3 in
                                                  let cvarloc_end = Parsing.rhs_end_pos 3 in
                                                  let loc = create_loc cvarloc_st cvarloc_end in
                                                  let cvar_exp_desc = 
                                                    Var { var_location = loc;
                                                          var_desc = ColonVar } in 
                                                  let cvar_exp = 
                                                    create_exp loc cvar_exp_desc in
                                                cvar_exp::$1 }
| functionArgs COMMA variableDeclaration       { $3::$1 } 
| functionArgs COMMA                           { $1 }


condition :
| functionCall 	%prec HIGHLEVEL                 { $1 }
| variable      %prec HIGHLEVEL                 { $1 }

/* IF THEN ELSE */

ifControl :
| IF condition thenTok thenBody END                   { let ifexp = IfExp 
                                                          { ifExp_test = $2;
                                                            ifExp_then = $4;
                                                            ifExp_else = None;
                                                            ifExp_kind = 
                                                              IfExp_expression_kind } in
                                                        let off_st = Parsing.rhs_start_pos 1 in
                                                        let off_end = Parsing.rhs_end_pos 5 in
                                                        let loc = 
                                                          create_loc off_st off_end in
                                                        create_exp loc (ControlExp ifexp) }
| IF condition thenTok thenBody elseTok elseBody END  { let ifexp = IfExp 
                                                          { ifExp_test = $2;
                                                            ifExp_then = $4;
                                                            ifExp_else = $6;
                                                            ifExp_kind = 
                                                              IfExp_expression_kind } in
                                                        let off_st = Parsing.rhs_start_pos 1 in
                                                        let off_end = Parsing.rhs_end_pos 7 in
                                                        let loc = 
                                                          create_loc off_st off_end in
                                                        create_exp loc (ControlExp ifexp) }
| IF condition thenTok thenBody elseIfControl END        { let ifexp = IfExp 
                                                             { ifExp_test = $2;
                                                               ifExp_then = $4;
                                                               ifExp_else = Some $5;
                                                               ifExp_kind = 
                                                                 IfExp_expression_kind } in
                                                        let off_st = Parsing.rhs_start_pos 1 in
                                                        let off_end = Parsing.rhs_end_pos 7 in
                                                        let loc = 
                                                          create_loc off_st off_end in
                                                        create_exp loc (ControlExp ifexp) }     
                                                          

thenBody :
| /* Empty */                                  { let off_st = Parsing.rhs_start_pos 1 in
                                                 let off_end = Parsing.rhs_end_pos 1 in
                                                 let loc = 
                                                   create_loc off_st off_end in
                                                 create_exp loc (SeqExp []) }
| expression                                   { $1 }


elseBody :
| /* Empty */                                  { None }
| expression                                   { Some $1 }


ifConditionBreak :
| SEMI						{ }
| SEMI EOL					{ }
| COMMA						{ }
| COMMA EOL					{ }
| EOL						{ }


thenTok :
| THEN                                          { }
| ifConditionBreak THEN				{ }
| ifConditionBreak THEN EOL			{ }
| THEN ifConditionBreak				{ }
| ifConditionBreak				{ }
| /* Empty */                                   { }


elseTok :
| ELSE						{ }
| ELSE COMMA					{ }
| ELSE SEMI					{ }
| ELSE EOL					{ }
| ELSE COMMA EOL				{ }
| ELSE SEMI EOL					{ }

elseIfControl :
| ELSEIF condition thenTok thenBody                   { let ifexp = 
                                                          ControlExp 
                                                            (IfExp 
                                                               { ifExp_test = $2;
                                                                 ifExp_then = $4;
                                                                 ifExp_else = None;
                                                                 ifExp_kind = 
                                                                   IfExp_expression_kind }) in
                                                        let off_st = Parsing.rhs_start_pos 1 in
                                                        let off_end = Parsing.rhs_end_pos 4 in
                                                        let loc = 
                                                          create_loc off_st off_end in
                                                        create_exp loc 
                                                          (SeqExp [create_exp loc ifexp]) }
| ELSEIF condition thenTok thenBody elseTok elseBody  { let ifexp = 
                                                          ControlExp 
                                                            (IfExp 
                                                               { ifExp_test = $2;
                                                                 ifExp_then = $4;
                                                                 ifExp_else = $6;
                                                                 ifExp_kind = 
                                                                   IfExp_expression_kind }) in
                                                        let off_st = Parsing.rhs_start_pos 1 in
                                                        let off_end = Parsing.rhs_end_pos 6 in
                                                        let loc = 
                                                          create_loc off_st off_end in
                                                        create_exp loc 
                                                          (SeqExp [create_exp loc ifexp]) }
| ELSEIF condition thenTok thenBody elseIfControl     { let ifexp = ControlExp 
                                                          (IfExp 
                                                             { ifExp_test = $2;
                                                               ifExp_then = $4;
                                                               ifExp_else = Some $5;
                                                               ifExp_kind = 
                                                                 IfExp_expression_kind }) in
                                                        let off_st = Parsing.rhs_start_pos 1 in
                                                        let off_end = Parsing.rhs_end_pos 6 in
                                                        let loc = 
                                                          create_loc off_st off_end in
                                                        create_exp loc 
                                                          (SeqExp [create_exp loc ifexp]) }
/* FOR */
forControl :
| FOR ID ASSIGN forIterator forConditionBreak forBody END               { let vardec_st = Parsing.rhs_start_pos 2 in
                                                                          let vardec_end = Parsing.rhs_end_pos 2 in
                                                                          let vardec_loc = create_loc vardec_st vardec_end in
                                                                          let vardec_desc = 
                                                                            { varDec_name = $2;
                                                                              varDec_init = $4;
                                                                              varDec_kind = VarDec_invalid_kind} in
                                                                          let forexp = ForExp
                                                                            { forExp_vardec_location = vardec_loc;
                                                                              forExp_vardec = vardec_desc;
                                                                              forExp_body = $6 } in
                                                                          let off_st = Parsing.rhs_start_pos 1 in
                                                                          let off_end = Parsing.rhs_end_pos 7 in
                                                                          let loc = 
                                                                            create_loc off_st off_end in
                                                                          create_exp loc (ControlExp forexp) }
| FOR LPAREN ID ASSIGN forIterator RPAREN forConditionBreak forBody END { let vardec_st = Parsing.rhs_start_pos 3 in
                                                                          let vardec_end = Parsing.rhs_end_pos 3 in
                                                                          let vardec_loc = create_loc vardec_st vardec_end in
                                                                          let vardec_desc = 
                                                                            { varDec_name = $3;
                                                                              varDec_init = $5;
                                                                              varDec_kind = VarDec_invalid_kind} in
                                                                          let forexp = ForExp
                                                                            { forExp_vardec_location = vardec_loc;
                                                                              forExp_vardec = vardec_desc;
                                                                              forExp_body = $8 } in
                                                                          let off_st = Parsing.rhs_start_pos 1 in
                                                                          let off_end = Parsing.rhs_end_pos 9 in
                                                                          let loc = 
                                                                            create_loc off_st off_end in
                                                                          create_exp loc (ControlExp forexp)}

forIterator :
| functionCall                                  { $1 }
| variable                                      { $1 }

forConditionBreak :
| EOL						{ }
| SEMI						{ }
| SEMI EOL					{ }
| COMMA						{ }
| COMMA EOL					{ }
| DO						{ }
| DO EOL					{ }
| /* Empty */					{ }

forBody :
| expression                                    { $1 }
| /* Empty */                                   { let off_st = Parsing.rhs_start_pos 1 in
                                                  let off_end = Parsing.rhs_end_pos 1 in
                                                  let loc = 
                                                    create_loc off_st off_end in
                                                  create_exp loc (SeqExp []) }

/* WHILE */
whileControl :
| WHILE condition whileConditionBreak whileBody END   { let wexp = 
                                                          WhileExp 
                                                            { whileExp_test = $2;
                                                              whileExp_body = $4 } in
                                                        let off_st = Parsing.rhs_start_pos 1 in
                                                        let off_end = Parsing.rhs_end_pos 5 in
                                                        let loc = create_loc off_st off_end in
                                                        create_exp loc (ControlExp wexp) }

whileBody :
| /* Empty */           { let off_st = Parsing.rhs_start_pos 1 in
                          let off_end = Parsing.rhs_end_pos 1 in
                          let loc = 
                            create_loc off_st off_end in
                          create_exp loc (SeqExp []) }
| expression            { $1 }

whileConditionBreak :
| COMMA                 { }
| SEMI                  { }
| DO                    { }
| DO COMMA              { }
| DO SEMI               { }
| THEN                  { }
| THEN COMMA            { }
| THEN SEMI             { }
| COMMENT EOL           { }
| EOL                   { }
| COMMA EOL             { }
| SEMI EOL              { }
| DO EOL                { }
| DO COMMA EOL          { }
| DO SEMI EOL           { }
| THEN EOL              { }
| THEN COMMA EOL        { }
| THEN SEMI EOL         { }
    
    
    
variable :
| matrix                                        { $1 }
| VARINT %prec LISTABLE                         { let doubleexp =
                                                    DoubleExp { doubleExp_value = $1;
                                                                doubleExp_bigDouble = ()} in
                                                  let off_st = Parsing.rhs_start_pos 1 in
                                                  let off_end = Parsing.rhs_end_pos 1 in
                                                  let loc = create_loc off_st off_end in
                                                  create_exp loc (ConstExp doubleexp)}
| NUM %prec LISTABLE                            { let doubleexp =
                                                    DoubleExp { doubleExp_value = $1;
                                                                doubleExp_bigDouble = ()} in
                                                  let off_st = Parsing.rhs_start_pos 1 in
                                                  let off_end = Parsing.rhs_end_pos 1 in
                                                  let loc = create_loc off_st off_end in
                                                  create_exp loc (ConstExp doubleexp)} 
| ID %prec LISTABLE                           { let varloc_st = Parsing.rhs_start_pos 1 in
                                                  let varloc_end = Parsing.rhs_end_pos 1 in
                                                  let varloc = create_loc varloc_st varloc_end in
                                                  let varexp = 
                                                    Var { var_location = varloc;
                                                          var_desc = SimpleVar $1 } in 
                                                  create_exp varloc varexp }


/* Matrix */

matrix :
| LBRACK matrixOrCellLines RBRACK             { let mle = Array.of_list (List.rev $2) in
                                                let mathexp =
                                                  MatrixExp { matrixExp_lines = mle } in
                                                let off_st = Parsing.rhs_start_pos 1 in
                                                let off_end = Parsing.rhs_end_pos 3 in
                                                let loc = create_loc off_st off_end in
                                                create_exp loc (MathExp mathexp) }
| LBRACK EOL matrixOrCellLines RBRACK         { let mle = Array.of_list (List.rev $3) in
                                                let mathexp =
                                                  MatrixExp { matrixExp_lines = mle } in
                                                let off_st = Parsing.rhs_start_pos 1 in
                                                let off_end = Parsing.rhs_end_pos 4 in
                                                let loc = create_loc off_st off_end in
                                                create_exp loc (MathExp mathexp) }
| LBRACK matrixOrCellColumns RBRACK           { let st_line = Parsing.rhs_start_pos 2 in
                                                let end_line = Parsing.rhs_end_pos 2 in
                                                let loc_line = create_loc st_line end_line in
                                                let mlec = 
                                                  { matrixLineExp_location = loc_line;
                                                    matrixLineExp_columns = Array.of_list (List.rev $2) } in
                                                let mle = Array.of_list [mlec] in
                                                let mathexp =
                                                  MatrixExp { matrixExp_lines = mle } in
                                                let off_st = Parsing.rhs_start_pos 1 in
                                                let off_end = Parsing.rhs_end_pos 3 in
                                                let loc = create_loc off_st off_end in
                                                create_exp loc (MathExp mathexp) }
| LBRACK EOL matrixOrCellColumns RBRACK        { let st_line = Parsing.rhs_start_pos 3 in
                                                 let end_line = Parsing.rhs_end_pos 3 in
                                                 let loc_line = create_loc st_line end_line in
                                                 let mlec = 
                                                   { matrixLineExp_location = loc_line;
                                                     matrixLineExp_columns = Array.of_list (List.rev $3) } in
                                                 let mle = Array.of_list [mlec] in
                                                 let mathexp =
                                                   MatrixExp { matrixExp_lines = mle } in
                                                 let off_st = Parsing.rhs_start_pos 1 in
                                                 let off_end = Parsing.rhs_end_pos 4 in
                                                 let loc = create_loc off_st off_end in
                                                 create_exp loc (MathExp mathexp) }
| LBRACK matrixOrCellLines matrixOrCellColumns RBRACK 
                                              { let st_line = Parsing.rhs_start_pos 3 in
                                                let end_line = Parsing.rhs_end_pos 3 in
                                                let loc_line = create_loc st_line end_line in
                                                let col = 
                                                  { matrixLineExp_location = loc_line; 
                                                    matrixLineExp_columns = Array.of_list $3 } in
                                                let mle = Array.of_list (List.rev (col::$2)) in
                                                let mathexp =
                                                  MatrixExp { matrixExp_lines = mle } in
                                                let off_st = Parsing.rhs_start_pos 1 in
                                                let off_end = Parsing.rhs_end_pos 4 in
                                                let loc = create_loc off_st off_end in
                                                create_exp loc (MathExp mathexp) }
| LBRACK EOL matrixOrCellLines matrixOrCellColumns RBRACK 
                                              { let st_line = Parsing.rhs_start_pos 3 in
                                                let end_line = Parsing.rhs_end_pos 3 in
                                                let loc_line = create_loc st_line end_line in
                                                let col = 
                                                  { matrixLineExp_location = loc_line; 
                                                    matrixLineExp_columns = Array.of_list $4 } in
                                                let mle = Array.of_list (List.rev (col::$3)) in
                                                let mathexp =
                                                  MatrixExp { matrixExp_lines = mle } in
                                                let off_st = Parsing.rhs_start_pos 1 in
                                                let off_end = Parsing.rhs_end_pos 4 in
                                                let loc = create_loc off_st off_end in
                                                create_exp loc (MathExp mathexp) }
| LBRACK EOL RBRACK                           { let mle = 
                                                  (Array.of_list []:matrixLineExp array) in
                                                let mathexp =
                                                  MatrixExp { matrixExp_lines = mle } in
                                                let off_st = Parsing.rhs_start_pos 1 in
                                                let off_end = Parsing.rhs_end_pos 3 in
                                                let loc = create_loc off_st off_end in
                                                create_exp loc (MathExp mathexp) }
| LBRACK RBRACK                               { let mle = 
                                                  (Array.of_list []:matrixLineExp array) in
                                                let mathexp =
                                                  MatrixExp { matrixExp_lines = mle } in
                                                let off_st = Parsing.rhs_start_pos 1 in
                                                let off_end = Parsing.rhs_end_pos 2 in
                                                let loc = create_loc off_st off_end in
                                                create_exp loc (MathExp mathexp) }
    

matrixOrCellLines: /* Use of list then cast to array */
| matrixOrCellLines matrixOrCellLine	              { $2::$1 }
| matrixOrCellLine                                    { [$1]}


matrixOrCellLineBreak :
| SEMI                                                          {  }
| EOL                                                           {  }
| matrixOrCellLineBreak EOL                                     {  }
| matrixOrCellLineBreak SEMI                                    {  }


matrixOrCellLine :
| matrixOrCellColumns matrixOrCellLineBreak                          { let st_line = Parsing.rhs_start_pos 1 in
                                                                       let end_line = Parsing.rhs_end_pos 1 in
                                                                       let loc_line = create_loc st_line end_line in
                                                                       { matrixLineExp_location = loc_line; 
                                                                         matrixLineExp_columns = 
                                                                           Array.of_list (List.rev $1) } }
| matrixOrCellColumns matrixOrCellColumnsBreak matrixOrCellLineBreak { let st_line = Parsing.rhs_start_pos 1 in
                                                                       let end_line = Parsing.rhs_end_pos 1 in
                                                                       let loc_line = create_loc st_line end_line in
                                                                       { matrixLineExp_location = loc_line; 
                                                                         matrixLineExp_columns = 
                                                                           Array.of_list (List.rev $1) } }
    
matrixOrCellColumns :
| matrixOrCellColumns matrixOrCellColumnsBreak variable         { $3::$1 }
| matrixOrCellColumns variable                                  { $2::$1 }
| variable                                                      { [$1] }


matrixOrCellColumnsBreak :
| matrixOrCellColumnsBreak COMMA				{  }
| COMMA								{  }


/* VARAIABLE DECLARATION */
variableDeclaration :
| assignable ASSIGN variable                                    { let assignexp = 
                                                                    AssignExp {assignExp_left_exp = $1;
                                                                               assignExp_right_exp = $3 } in
                                                                  let off_st = Parsing.rhs_start_pos 1 in
                                                                  let off_end = Parsing.rhs_end_pos 3 in
                                                                  let loc = create_loc off_st off_end in
                                                                  create_exp loc assignexp}


assignable :
| ID %prec LISTABLE                                             { let varloc_st = Parsing.rhs_start_pos 1 in
                                                                  let varloc_end = Parsing.rhs_end_pos 1 in
                                                                  let varloc = create_loc varloc_st varloc_end in
                                                                  let varexp = 
                                                                    Var { var_location = varloc;
                                                                          var_desc = SimpleVar $1 } in 
                                                                  create_exp varloc varexp}

/*

*/














  