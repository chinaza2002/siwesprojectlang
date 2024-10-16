module Checker

extend analysis::typepal::TypePal;
import Syntax;

data AType 
    = classType(str cName)
    | methodType(AType returnType, AType argTypes)
    | intType()
    | boolType()
    | strType()
    // | listType()
    ;

data IdRole 
    = variableId()
    | classId()
    | constructorId()
    | methodId()
    | paramId()
    | fieldId()
    ;
data PathRole 
    = extendsPath()
    ;

str prettyAType(boolType()) = "Bool";
str prettyAType(intType()) = "Int";
str prettyAType(strType()) = "Str";
str prettyAType(classType(str cName)) = cName;
str prettyAType(methodType(AType returnType, AType argTypes)) 
    = "method <prettyAType(returnType)>(<prettyAType(argTypes)>)";
// str prettyAType(listType()) = "List";

private str key_extendsRelation = "extends-relation";

data ClassInfo
    = classInfo(ClassId cid, ClassId ecid)
    ;
    
data ScopeRole
    = classScope();

tuple[list[str] typeNames, set[IdRole] idRoles] splGetTypeNamesAndRole(classType(str name)){
    return <[name], {classId()}>;
}

default tuple[list[str] typeNames, set[IdRole] idRoles] splGetTypeNamesAndRole(AType t){
    return <[], {}>;
}

bool splMayOverload (set[loc] defs, map[loc, Define] defines) {
    roles = {defines[def].idRole | def <- defs};
    return roles == {classId(), constructorId()};
}

 void splPreCollectInitialization(Tree _, Collector c){
    class_def = c.predefine("Object",  classId(), |global-scope:///|, defType(classType("Object")));
    c.predefineInScope(class_def, "Object", constructorId(), defType(methodType(classType("Object"), atypeList([]))));
}

TModel splPreSolver(map[str,Tree] _, TModel tm) {
    if(lrel[str,str] extendsRel := tm.store[key_extendsRelation]){
        extends = toSet(extendsRel)*;
    
        bool SPLsubtype(classType(c1), classType(c2)) = c1 == c2 || c2 == "Object" || <c1,c2> in extends;
        default bool SPLsubtype(AType t1, AType t2) = t1 == t2;
    
        tm.config.isSubType = SPLsubtype;
        return tm;
     } else {
        throw "Inconsistent value of key_extendsRelation: <tm.store[key_extendsRelation]>";
     }
}

TypePalConfig splConfig() =
    tconfig(mayOverload         = splMayOverload,
            getTypeNamesAndRole = splGetTypeNamesAndRole,
            preSolver           = splPreSolver);


void collect(current: (ClassDeclaration) `class <ClassId cid> extends <ClassId ecid> { <FieldDecl* fieldDecls> <ConstructorDeclr constructorDecl> <MethodDecl* methoddecls> }`, Collector c) {
    c.define("<cid>", classId(), current, defType(classType("<cid>")));
    c.enterScope(current);
        c.push(key_extendsRelation, <"<cid>", "<ecid>">);
        scope = c.getScope();
        c.setScopeInfo(scope, classScope(), classInfo(cid, ecid));
        c.addPathToDef(ecid, {classId()}, extendsPath());
        collect(fieldDecls, constructorDecl, methoddecls, c);
    c.leaveScope(current);
}

tuple[loc scope, ClassId cid, ClassId ecid] getCurrentClass(Collector c){
    classScopes = c.getScopeInfo(classScope());
    for(<scope, scopeInfo> <- classScopes){
        if(classInfo(cid1, ecid1) := scopeInfo){
            return <scope, cid1, ecid1>;
        } else  {
            throw "Inconsistent info from class scope: <scopeInfo>";
        }
    }
    
    throw  "No surrounding class scope found";
}

void collect(current: (ConstructorDeclr ) `<ClassId cid> <Parameters params> { <SuperCall superCall> <FieldAssignment* fieldAssignments> }`, Collector c){
    <scope, cid1, ecid1> = getCurrentClass(c);
    if("<cid>" != "<cid1>")
        c.report(error(current, "Expected constructor name %q, found %q", "<cid1>", "<cid>"));
    c.enterScope(current);
        tp = methodType(classType("<cid1>"), atypeList([classType("<p.cid>") | Parameter p <- params.params]));
        c.defineInScope(scope, "<cid>", constructorId(), current, defType(tp));
        collect(params,superCall, fieldAssignments, c);
    c.leaveScope(current);            
}

void collect(current: (Parameter) `<ClassId cid> <Id id>`, Collector c){
     c.define("<id>", paramId(), current, defType(classType("<cid>")));   
}

void collect(fd: (FieldDecl) `<ClassId cid> <Id id> ;`, Collector c){
     c.define("<id>", fieldId(), id, defType(classType("<cid>")));
}

void collect(current: (MethodDecl) `<ClassId cid> <Id mid> <Parameters params> { return <Expr exp> ; }`,  Collector c){   
     param_list =  [param | param <- params.params];
     c.define("<mid>", methodId(), current, defType(param_list + exp, AType(Solver s) { return methodType(s.getType(exp), atypeList([s.getType(param) | param <- param_list])); }));
     c.enterScope(current);
         c.requireSubType(exp, classType("<cid>"), error(current,  "Actual return type %t should be subtype of declared return type %t", exp, cid));
         collect(params, exp, c);
     c.leaveScope(current);
}

void collect(current: (Parameters) `( <{Parameter ","}* params> )`, Collector c){
    collect(params, c);
}

void collect(current: (SuperCall) `super ( <{Variable ","}* vars> );`, Collector c){
    varList = [var | var <- vars];
    <scope, cid, ecid> = getCurrentClass(c);

    c.use(ecid, {constructorId()});
    c.calculate("super call", current, ecid + varList,
        AType (Solver s) { 
                stype = s.getType(ecid);
                if(methodType(_, formalType) := stype){
                   argType = atypeList([s.getType(exp) | exp <- varList]);
                   s.requireSubType(argType, formalType, error(current,  "Expected arguments %t, found %t", formalType, argType));
              } else {
                 s.report(error(current,  "Method type required in super call, found %t", stype));
              }
              return classType("<ecid>");
        });
    collect(vars, c);  
}

void collect(current: (FieldAssignment) `this . <Field field> = <Expr exp> ;`, Collector c){
    c.use(field, {fieldId()});
    c.require("field assignment", current, [field, exp],
        void(Solver s){
            s.requireSubType(exp, field, error(current, "In assignment to field %q, expected %t, found %t", field, field, exp));
        });
    collect(exp, c);
}

void collect(Class cls, Collector c){
    c.use(cls.id, {classId()});
}

void collect(Constructor cons, Collector c){
     c.use(cons.id, {constructorId()});
}

void collect(Variable var, Collector c){
     c.use(var.id, {paramId(), fieldId()});
}

void collect(Field fld, Collector c){
     c.use(fld.id, {fieldId()});
}

void collect(Method mtd, Collector c){
     c.use(mtd.id, {methodId()});
}

void collect(current: (VariableDeclaration) `var <Id name> = <Expr exp> ;`, Collector c){
    c.define("<name>",variableId(), current, defType(exp));
    collect(exp, c);
}

// void collect(current: (VariableDeclaration) `var <Id name>;`, Collector c){
//     // c.fact(current, )
// }

// void collect(current: (FunctionDeclaration) `function <Id name> (<{Id ","}* params> ) { <Body body>}`, Collector c){
//     c.define("<name>", functionId(), current, defType(body));
// }

// void collect(current: (Body) `<Declarations* decList> <ReturnStatement? returnStatement>`, Collector c){
    
// }

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