module Checker

extend analysis::typepal::TypePal;
import Syntax;

data AType 
    = classType()
    | functionType()
    | intType()
    | boolType()
    | strType()
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
str prettyAType(functionType()) = "Function";
str prettyAType(listType()) = "List";

void collect(current: (VariableDeclaration) `var <Id name> = <Expr exp> ;`, Collector c){
    c.define("<name>",variableId(), current, defType(exp));
    collect(exp, c);
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

//idk how to do it for listexp

// void collect(current: (Expr) `[<{Expr ","}*>]`, Collector c){

// }

void collect(current: (Expr) `( <Expr bracketExpr> )`, Collector c){
    c.fact(current, bracketExpr);
    collect(e, c);
}

void collect(current: (Expr) `<Expr postIncrExp> ++`, Collector c){     //not sure this is correct
    c.fact(current, postIncrExp);
}

void collect(current: (Expr) `<Expr postDecrExp> --`, Collector c){     //this too
    c.fact(current, postDecrExp);
}

void collect(current: (Expr) `++ <Expr preIncrExp>`, Collector c){     //this too
    c.fact(current, preIncrExp);
}

void collect(current: (Expr) `-- <Expr preDecrExp>`, Collector c){     //this too
    c.fact(current, preDecrExp);
}

void collect(current: (Expr) `<Expr lhs> * <Expr rhs>`, Collector c){
    c.calculate("multipllication", current, [lhs, rhs], 
    AType (Solver s){
        switch(<s.getType(lhs), s.getType(rhs)>){
            case <intType(), intType()>: return intType();
            case <boolType(), boolType()>: return boolType();
            case <strType(), strType()>: return strType();
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
                case <boolType(), boolType()>: return boolType();
                case <strType(), strType()>: return strType();
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
                case <boolType(), boolType()>: return boolType();
                case <strType(), strType()>: return strType();
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
                case <boolType(), boolType()>: return boolType();
                case <strType(), strType()>: return strType();
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
                case <boolType(), boolType()>: return boolType();
                case <strType(), strType()>: return strType();
                default: {
                    s.report(error(current, "`-` not defined for %t and %t", lhs, rhs));
                    return intType();
                }
            }
        });
    collect(lhs, rhs, c);
}

void collect(current: (Expr) `<Expr lhs> \< <Expr lhs>`, Collector c){
    collect(lhs, rhs, s);
    c.calculate("Lt", current, [lhs, rhs], 
        AType (Solver s) {
            switch([s.getType(lhs), s.getType(rhs)]){
                case [intType(), intType()] : return boolType();
                case [strType(), strType()] : return boolType();
                default : s.report(error(current, "%q requires two comparable types but found %t and %t", "\<", lhs, rhs));
            }
            return strType();
        });
}

void collect(current: (Expr) `<Expr lhs> \> <Expr lhs>`, Collector c){
    collect(lhs, rhs, s);
    c.calculate("Gt", current, [lhs, rhs], 
        AType (Solver s) {
            switch([s.getType(lhs), s.getType(rhs)]){
                case [intType(), intType()] : return boolType();
                case [strType(), strType()] : return boolType();
                default : s.report(error(current, "%q requires two comparable types but found %t and %t", "\>", lhs, rhs));
            }
            return strType();
        });
}

void collect(current: (Expr) `<Expr lhs> \<= <Expr lhs>`, Collector c){
    collect(lhs, rhs, s);
    c.calculate("Leq", current, [lhs, rhs], 
        AType (Solver s) {
            switch([s.getType(lhs), s.getType(rhs)]){
                case [intType(), intType()] : return boolType();
                case [strType(), strType()] : return boolType();
                default : s.report(error(current, "%q requires two comparable types but found %t and %t", "\<=", lhs, rhs));
            }
            return strType();
        });
}

void collect(current: (Expr) `<Expr lhs> \>= <Expr lhs>`, Collector c){
    collect(lhs, rhs, s);
    c.calculate("Geq", current, [lhs, rhs], 
        AType (Solver s) {
            switch([s.getType(lhs), s.getType(rhs)]){
                case [intType(), intType()] : return boolType();
                case [strType(), strType()] : return boolType();
                default : s.report(error(current, "%q requires two comparable types but found %t and %t", "\>=", lhs, rhs));
            }
            return strType();
        });
}

void collect(current: (Expr) `<Expr lhs> == <Expr lhs>`, Collector c){
    collect(lhs, rhs, s);
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

void collect(current: (Expr) `<Expr lhs> != <Expr lhs>`, Collector c){
    collect(lhs, rhs, s);
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

void collect(current: (Expr) `<Expr lhs> = <Expr lhs>`, Collector c){
    collect(lhs, rhs, s);
    c.calculate("assign", current, [lhs, rhs], 
        AType (Solver s) {
            switch([s.getType(lhs), s.getType(rhs)]){
                case [intType(), intType()] : return boolType();
                case [strType(), strType()] : return boolType();
                default : s.report(error(current, "%q requires two comparable types but found %t and %t", "=", lhs, rhs));
            }
            return strType();
        });
}

void collect(current: (Expr) `<Expr lhs> *= <Expr lhs>`, Collector c){
    collect(lhs, rhs, s);
    c.calculate("assignmul", current, [lhs, rhs], 
        AType (Solver s) {
            switch([s.getType(lhs), s.getType(rhs)]){
                case [intType(), intType()] : return intType();
                default : s.report(error(current, "%q requires two equal types but found %t and %t", "*=", lhs, rhs));
            }
            return intType();
        });
}

void collect(current: (Expr) `<Expr lhs> /= <Expr lhs>`, Collector c){
    collect(lhs, rhs, s);
    c.calculate("assigndiv", current, [lhs, rhs], 
        AType (Solver s) {
            switch([s.getType(lhs), s.getType(rhs)]){
                case [intType(), intType()] : return intType();
                default : s.report(error(current, "%q requires two equal types but found %t and %t", "/=", lhs, rhs));
            }
            return intType();
        });
}

void collect(current: (Expr) `<Expr lhs> %= <Expr lhs>`, Collector c){
    collect(lhs, rhs, s);
    c.calculate("assignmodulo", current, [lhs, rhs], 
        AType (Solver s) {
            switch([s.getType(lhs), s.getType(rhs)]){
                case [intType(), intType()] : return intType();
                default : s.report(error(current, "%q requires two equal types but found %t and %t", "%=", lhs, rhs));
            }
            return intType();
        });
}

void collect(current: (Expr) `<Expr lhs> += <Expr lhs>`, Collector c){
    collect(lhs, rhs, s);
    c.calculate("assignadd", current, [lhs, rhs], 
        AType (Solver s) {
            switch([s.getType(lhs), s.getType(rhs)]){
                case [intType(), intType()] : return intType();
                default : s.report(error(current, "%q requires two equal types but found %t and %t", "+=", lhs, rhs));
            }
            return intType();
        });
}

void collect(current: (Expr) `<Expr lhs> -= <Expr lhs>`, Collector c){
    collect(lhs, rhs, s);
    c.calculate("assignsub", current, [lhs, rhs], 
        AType (Solver s) {
            switch([s.getType(lhs), s.getType(rhs)]){
                case [intType(), intType()] : return intType();
                default : s.report(error(current, "%q requires two equal types but found %t and %t", "-=", lhs, rhs));
            }
            return intType();
        });
}