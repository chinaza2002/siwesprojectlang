module Test 

import Syntax;
import AST;
import ParseTree;

Begin testBeginSyntax(loc file = |project://siwesprojectlang/src/main/rascal/tests.spl|){
    return parse(#Begin, file);
}

AST::Begin testBegin(loc file = |project://siwesprojectlang/src/main/rascal/tests.spl|){
    return implode(#AST::Begin, parse(#Syntax::Begin, file));
}