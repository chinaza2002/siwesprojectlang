module Syntax

extend CommonLex;

start syntax Begin 
    = declarations : Declarations+ decList
    ;

syntax Declarations 
    = vardec : VariableDeclaration variableDeclaration
    | classdec : ClassDeclaration classDeclaration
    | funcdec : FunctionDeclaration functionDeclaration
    | statdec : Statements statmentDeclaration
    ;

syntax VariableDeclaration 
    = initialization : "var" Id name "=" Expr exp ";"
    | noninitialization : "var" Id name ";"
    ;


syntax FunctionDeclaration 
    = functiondefinition : "function" Id name "(" {Id ","}* params ")" "{" Body body "}"
    ;

syntax Body 
    = bodydefinitions : Declarations* declList ReturnStatement? returnStatement
    ;

syntax ReturnStatement 
    = returndefinition : "return" Expr exp ";"
    ;

syntax ClassDeclaration 
    = classdefinition : "class" Id className ExtendPart? optionalExtend "{" ConstructorDeclr? constructorDecl Body body "}"
    ;

syntax ExtendPart 
    = extenddefinition : "extends" Id name
    ;

syntax ConstructorDeclr 
    = constructordefinition : "constructor" "(" {Id ","}* constructorParam  ")" "{" Body body "}"
    ;

syntax Statements 
    = forloop : "for" "(" VariableDeclaration variableDeclaration ";" Expr condition ";" Expr exp")" "{" Body body "}"
    | forinloop :"for" "(" VariableDeclaration variableDeclaration "in" Expr exp ")" "{" Body body "}"
    | whileloop : "while" "(" Expr cond ")" "{" Body body "}"
    | dowhileloop : "do" "{" Body "}" "while" "(" Expr cond")"
    | ifstatement : "if" "(" Expr cond ")" "{" Body body "}" 
    | ifelsestatement : "if" "(" Expr cond ")" "{" Body ifBody "}" "else" "{" Body elseBody "}"
    | switchstatement : "switch" "(" Expr cond ")" "{" CasePart* casePart "default" ":" Body defaultBody "}"
    | trycatch : "try" "{" Body tryBody "}" "catch" "(" Id catchException ")" "{" Body catchBody"}"
    | tryfinally : "try" "{" Body tryBody "}" "finally" "{" Body finallyBody "}"
    | trycatchfinally : "try" "{" Body tryBody "}" "catch" "(" Id  catchException ")" "{" Body catchBody "}" "finally" "{" Body finallyBody"}"
    | breakstatement : "break" ";"
    | continuestatement : "continue" ";"
    ;

syntax CasePart 
    = casestatement : "case" Expr caseExp ":" Body caseBody
    ;


syntax Expr
    = idExp : Id idName
    | intexp : Integer intVal
    | boolexp : Boolean boolVal
    | strexp : String strVal
    | listexp : "[" {Expr ","}* arrayExp "]"
    | bracket bracketexp : "(" Expr bracketExpr")"
    > postincrement : Expr postIncrExp "++"
    | postdecrement : Expr postDecrExp "--"
    > preincrement : "++" Expr preIncrExp
    | predecrement : "--" Expr preDecrExp
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