module Checker

extend analysis::typepal::TypePal;
import Syntax;


data AType 
    = classType()
    | functionType()
    | intType()
    | boolType()
    | strType()
    | voidType()
    | listType()
    ;

data IdRole 
    = variableId()
    | classId()
    | functionId()
    ;

str prettyAType(boolType()) = "Bool";
str prettyAType(intType()) = "Int";
str prettyAType(strType()) = "Str";
str prettyAType(classType()) = "Class";
str prettyAType(listType()) = "List";



void collect(current: (VariableDeclaration) `var <Id name> = <Expr exp> ;`, Collector c){
    c.define("<name>",variableId(), current, defType(exp));
    collect(exp, c);
}

void collect(current: (ConstructorDeclr) `constructor ( <{Id ","}* constructorParam> ) { <Body body> }`, Collector c){
    for (identifier <- constructorParam){
        collect(identifier,c);
    }
    c.enterScope(current);{
        collect(body,c);
    }
    c.leaveScope(current);
}


void collect(current: (ClassDeclaration) `class <Id className> { <ConstructorDeclr? constructorDecl> <Body body> }`, Collector c){
    c.define("<className>",classId(),current,defType(classType()));
    c.enterScope(current);{
        for (contrct <- constructorDecl){
            collect(contrct, c);
        }
        collect(body, c);
    }
    c.leaveScope(current);
}

void collect(current: (ReturnStatement) `return <Expr exp> ;`, Collector c){
    c.fact(current, exp);
    collect(exp, c);
}

void collect(current: (FunctionDeclaration) `function <Id name> (<{Expr ","}* params> ) { <Body body>}`, Collector c){
    for (ret <- body.returnStatement){
        c.define("<name>", functionId(), current, defType(ret));
    }
    for (parameter <- params){
        collect(parameter,c);
    }
    c.enterScope(current);{
        collect(body, c);
    }
    c.leaveScope(current);
}

void collect(current: (Body) `<Declarations* decList> <ReturnStatement? returnStatement>`, Collector c){
    collect(decList,c);
    for (ret <- returnStatement){
        collect(ret,c);
    }
}

void collect(current: (Expr) `<Id idName>`, Collector c){
    c.use(idName, {variableId()});
}

void collect(current: (Expr) `<Integer intVal>`, Collector c){
    c.fact(current, intType());
}

void collect(current: (Expr) `<Boolean boolVal>`, Collector c){
    c.fact(current, boolType());
}

void collect(current: (Expr) `<String strVal>`, Collector c){
    c.fact(current, strType());
}

void collect(current: (Expr) `[ <{Expr ","}* arrayExp>]`, Collector c){
    c.fact(current, listType());
    for (arrayitem <- arrayExp){
        collect(arrayitem, c);
    }
}

void collect(current: (Expr) `( <Expr bracketExpr> )`, Collector c){
    c.fact(current, bracketExpr);
    collect(bracketExpr, c);
}

void collect(current: (Expr) `<Expr postIncrExp> ++`, Collector c){     //not sure this is correct
    c.fact(current, defType(postIncrExp));
    collect(postIncrExp, c);
}

void collect(current: (Expr) `<Expr postDecrExp> --`, Collector c){     //this too
    c.fact(current, defType(postDecrExp));
    collect(postDecrExp, c);
}

void collect(current: (Expr) `++ <Expr preIncrExp>`, Collector c){     //this too
    c.fact(current, defType(preIncrExp));
    collect(preIncrExp, c);
}

void collect(current: (Expr) `-- <Expr preDecrExp>`, Collector c){     //this too
    c.fact(current, defType(preDecrExp));
    collect(preDecrExp, c);
}

void collect(current: (Expr) `<Expr lhs> * <Expr rhs>`, Collector c){
    c.calculate("multipllication", current, [lhs, rhs], 
    AType (Solver s){
        switch(<s.getType(lhs), s.getType(rhs)>){
            case <intType(), intType()>: return intType();
            default: {
                s.report(error(current, "`*` not defined for %t and %t", lhs, rhs));
                return intType();
            }
        }
    });
}

void collect(current: (Expr) `<Expr lhs> / <Expr rhs>`, Collector c){
    c.calculate("division", current, [lhs, rhs], 
        AType (Solver s){
            switch(<s.getType(lhs), s.getType(rhs)>){
                case <intType(), intType()>: return intType();
                default: {
                    s.report(error(current, "`/` not defined for %t and %t", lhs, rhs));
                    return intType();
                }
            }
        });
    collect(lhs, rhs, c);
}

void collect(current: (Expr) `<Expr lhs> % <Expr rhs>`, Collector c){
    c.calculate("modulus", current, [lhs, rhs], 
        AType (Solver s){
            switch(<s.getType(lhs), s.getType(rhs)>){
                case <intType(), intType()>: return intType();
                default: {
                    s.report(error(current, "`%` not defined for %t and %t", lhs, rhs));
                    return intType();
                }
            }
        });
    collect(lhs, rhs, c);
}

void collect(current: (Expr) `<Expr lhs> + <Expr rhs>`, Collector c){
    c.calculate("addition", current, [lhs, rhs], 
        AType (Solver s){
            switch(<s.getType(lhs), s.getType(rhs)>){
                case <intType(), intType()>: return intType();
                default: {
                    s.report(error(current, "`+` not defined for %t and %t", lhs, rhs));
                    return intType();
                }
            }
        });
    collect(lhs, rhs, c);
}

void collect(current: (Expr) `<Expr lhs> - <Expr rhs>`, Collector c){
    c.calculate("subtraction", current, [lhs, rhs], 
        AType (Solver s){
            switch(<s.getType(lhs), s.getType(rhs)>){
                case <intType(), intType()>: return intType();
                default: {
                    s.report(error(current, "`-` not defined for %t and %t", lhs, rhs));
                    return intType();
                }
            }
        });
    collect(lhs, rhs, c);
}

void collect(current: (Expr) `<Expr lhs> \< <Expr rhs>`, Collector c){
    collect(lhs, rhs, c);
    c.calculate("Lt", current, [lhs, rhs], 
        AType (Solver s) {
            switch([s.getType(lhs), s.getType(rhs)]){
                case [intType(), intType()] : return boolType();
                default : s.report(error(current, "%q requires two comparable types but found %t and %t", "\<", lhs, rhs));
            }
            return strType();
        });
}

void collect(current: (Expr) `<Expr lhs> \> <Expr rhs>`, Collector c){
    collect(lhs, rhs, c);
    c.calculate("Gt", current, [lhs, rhs], 
        AType (Solver s) {
            switch([s.getType(lhs), s.getType(rhs)]){
                case [intType(), intType()] : return boolType();
                default : s.report(error(current, "%q requires two comparable types but found %t and %t", "\>", lhs, rhs));
            }
            return strType();
        });
}

void collect(current: (Expr) `<Expr lhs> \<= <Expr rhs>`, Collector c){
    collect(lhs, rhs, c);
    c.calculate("Leq", current, [lhs, rhs], 
        AType (Solver s) {
            switch([s.getType(lhs), s.getType(rhs)]){
                case [intType(), intType()] : return boolType();
                default : s.report(error(current, "%q requires two comparable types but found %t and %t", "\<=", lhs, rhs));
            }
            return strType();
        });
}

void collect(current: (Expr) `<Expr lhs> \>= <Expr rhs>`, Collector c){
    collect(lhs, rhs, c);
    c.calculate("Geq", current, [lhs, rhs], 
        AType (Solver s) {
            switch([s.getType(lhs), s.getType(rhs)]){
                case [intType(), intType()] : return boolType();
                default : s.report(error(current, "%q requires two comparable types but found %t and %t", "\>=", lhs, rhs));
            }
            return strType();
        });
}

void collect(current: (Expr) `<Expr lhs> == <Expr rhs>`, Collector c){
    collect(lhs, rhs, c);
    c.calculate("Eq", current, [lhs, rhs], 
        AType (Solver s) {
            switch([s.getType(lhs), s.getType(rhs)]){
                case [intType(), intType()] : return boolType();
                case [strType(), strType()] : return boolType();
                default : s.report(error(current, "%q requires two comparable types but found %t and %t", "==", lhs, rhs));
            }
            return strType();
        });
}

void collect(current: (Expr) `<Expr lhs> != <Expr rhs>`, Collector c){
    collect(lhs, rhs, c);
    c.calculate("Neq", current, [lhs, rhs], 
        AType (Solver s) {
            switch([s.getType(lhs), s.getType(rhs)]){
                case [intType(), intType()] : return boolType();
                case [strType(), strType()] : return boolType();
                default : s.report(error(current, "%q requires two comparable types but found %t and %t", "!=", lhs, rhs));
            }
            return strType();
        });
}

void collect(current: (Expr) `<Expr lhs> = <Expr rhs>`, Collector c){
    collect(lhs, rhs, c);
    c.calculate("assign", current, [lhs, rhs], 
        AType (Solver s) {
            switch([s.getType(lhs), s.getType(rhs)]){
                case [strType(), intType()] : return intType();
                case [strType(), strType()] : return strType();
                case [strType(), boolType()] : return boolType();
                default : s.report(error(current, "%q requires two comparable types but found %t and %t", "=", lhs, rhs));
            }
            return strType();
        });
}

void collect(current: (Expr) `<Expr lhs> *= <Expr rhs>`, Collector c){
    collect(lhs, rhs, c);
    c.calculate("assignmul", current, [lhs, rhs], 
        AType (Solver s) {
            switch([s.getType(lhs), s.getType(rhs)]){
                case [strType(), intType()] : return intType();
                default : s.report(error(current, "%q requires two equal types but found %t and %t", "*=", lhs, rhs));
            }
            return intType();
        });
}

void collect(current: (Expr) `<Expr lhs> /= <Expr rhs>`, Collector c){
    collect(lhs, rhs, c);
    c.calculate("assigndiv", current, [lhs, rhs], 
        AType (Solver s) {
            switch([s.getType(lhs), s.getType(rhs)]){
                case [strType(), intType()] : return intType();
                default : s.report(error(current, "%q requires two equal types but found %t and %t", "/=", lhs, rhs));
            }
            return intType();
        });
}

void collect(current: (Expr) `<Expr lhs> %= <Expr rhs>`, Collector c){
    collect(lhs, rhs, c);
    c.calculate("assignmodulo", current, [lhs, rhs], 
        AType (Solver s) {
            switch([s.getType(lhs), s.getType(rhs)]){
                case [strType(), intType()] : return intType();
                default : s.report(error(current, "%q requires two equal types but found %t and %t", "%=", lhs, rhs));
            }
            return intType();
        });
}

void collect(current: (Expr) `<Expr lhs> += <Expr rhs>`, Collector c){
    collect(lhs, rhs, c);
    c.calculate("assignadd", current, [lhs, rhs], 
        AType (Solver s) {
            switch([s.getType(lhs), s.getType(rhs)]){
                case [strType(), intType()] : return intType();
                default : s.report(error(current, "%q requires two equal types but found %t and %t", "+=", lhs, rhs));
            }
            return intType();
        });
}

void collect(current: (Expr) `<Expr lhs> -= <Expr rhs>`, Collector c){
    collect(lhs, rhs, c);
    c.calculate("assignsub", current, [lhs, rhs], 
        AType (Solver s) {
            switch([s.getType(lhs), s.getType(rhs)]){
                case [strType(), intType()] : return intType();
                default : s.report(error(current, "%q requires two equal types but found %t and %t", "-=", lhs, rhs));
            }
            return intType();
        });
}