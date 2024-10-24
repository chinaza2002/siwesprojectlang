module Test 

import Syntax;
import AST;
import ParseTree;
import IO;
import LanguageServer;

test bool testSyntax(){
    loc file = |project://siwesprojectlang/src/main/rascal/tests.spl|;
    ParseAndImplode(file);
    return true;
}

void ParseAndImplode(loc code){
    pt = parse(#start[Begin], code);
    ast = implode(#AST::Begin, pt);
    println(ast);
}