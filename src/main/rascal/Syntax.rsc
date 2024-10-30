module Syntax

extend CommonLex;

start syntax Begin 
    = declarations : Declarations+ decList
    ;

syntax Declarations 
    = vardec : VariableDeclaration variableDeclaration
    | classdec : ClassDeclaration classDeclaration
    | funcdec : FunctionDeclaration functionDeclaration
    | statdec : Statement statementDeclaration
    | exprdec : Expr exprDeclaration
    ;

syntax VariableDeclaration 
    = initialization : "var" Id name "=" Expr exp ";"
    ;


syntax FunctionDeclaration 
    = functiondefinition : "function" Id name "(" {Expr ","}* params ")" "{" Body body "}"
    ;

syntax Body 
    = bodydefinitions : Declarations* declList ReturnStatement? returnStatement
    ;

syntax ReturnStatement 
    = returndefinition : "return" Expr exp ";"
    ;

syntax ClassDeclaration 
    = classdefinition : "class" Id className "{" ConstructorDeclr? constructorDecl Body body "}"
    ;


syntax ConstructorDeclr 
    = constructordefinition : "constructor" "(" {Id ","}* constructorParam  ")" "{" Body body "}"
    ;
syntax Statement
   = ifstatement : "if" "(" Expr cond ")" "then" "{" Body thenPart "}" "else" "{" Body elsePart "}"
   | whilestatment : "while" "(" Expr cond ")" "do" "{" Body body "}"
   ; 

syntax Expr
    = idexp : Id idName
    | intexp : Integer intVal
    | boolexp : Boolean boolVal
    | strexp : String strVal
    | listexp : "[" {Expr ","}* arrayExp "]"
    | bracket bracketexp : "(" Expr bracketExpr")"
    > left mul : Expr lhs "*" Expr rhs
    > left div : Expr lhs "/" Expr rhs
    > left modulo : Expr lhs "%" Expr rhs
    > left add: Expr lhs "+" Expr rhs
    > left sub : Expr lhs "-" Expr rhs
    > non-assoc lt : Expr lhs "\<" Expr rhs
    > non-assoc gt : Expr lhs "\>" Expr
    > non-assoc leq : Expr lhs "\<=" Expr
    > non-assoc geq : Expr lhs "\>=" Expr
    > right eq : Expr lhs "==" Expr rhs
    > right neq : Expr lhs "!=" Expr rhs
    > right assign : Expr lhs "=" Expr rhs 
    > right assignmul : Expr lhs "*=" Expr rhs 
    > right assigndiv : Expr lhs "/=" Expr rhs 
    > right assignmodulo : Expr lhs "%=" Expr rhs 
    > right assignadd : Expr lhs "+=" Expr rhs 
    > right assignsub : Expr lhs "-=" Expr rhs
    ;