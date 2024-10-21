module AST

// extend CommonLex;
data Begin 
    = declarations(list[Declarations] declList)
    ;

data Declarations 
    = vardec(VariableDeclaration variableDeclaration)
    | classdec(ClassDeclaration classDeclaration)
    | funcdec(FunctionDeclaration functionDeclaration)
    ;

data VariableDeclaration
    = initialization(str name, Expr exp)
    ;

data FunctionDeclaration 
    = functiondefinition(str name, list[str] params, Body body)
    ;

data Body 
    = bodydefinitions(list[Declarations] declList, list[ReturnStatement] returnStatement)
    ;

data ReturnStatement 
    = returndefinition(Expr exp)
    ;

data ClassDeclaration
    = classdefinition(str className,  list[ConstructorDeclr] constructorDecl, Body body)
    ;


data ConstructorDeclr 
    = constructordefinition(list[str] constructorParam, Body body)
    ;


data Expr
  = idExp(str name)
  | intexp(int intVal)
  | boolexp(bool boolVal)
  | strexp(str strVal)
  | listexp(list[Expr] arrayExp)
  | bracketexp(Expr bracketExpr)
  | postincrement(Expr postIncrExp)
  | postdecrement(Expr postDecrExp)
  | preincrement(Expr preIncrExp)
  | predecrement(Expr preDecrExp)
  | mul(Expr lhs, Expr rhs)
  | div(Expr lhs, Expr rhs)
  | modulo(Expr lhs, Expr rhs)
  | add(Expr lhs, Expr rhs)
  | sub(Expr lhs, Expr rhs)
  | lt(Expr lhs, Expr rhs)
  | gt(Expr lhs, Expr rhs)
  | leq(Expr lhs, Expr rhs)
  | geq(Expr lhs, Expr rhs)
  | eq(Expr lhs, Expr rhs)
  | neq(Expr lhs, Expr rhs)
  | assign(Expr lhs, Expr rhs)
  | assignmul(Expr lhs, Expr rhs)
  | assigndiv(Expr lhs, Expr rhs)
  | assignmodulo(Expr lhs, Expr rhs)
  | assignadd(Expr lhs, Expr rhs)
  | assignsub(Expr lhs, Expr rhs)
    ;