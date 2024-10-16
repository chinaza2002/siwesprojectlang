module TestChecker

extend analysis::typepal::TestFramework;
extend Checker;
import Syntax;
import ParseTree;

TModel splTModelForTree(Tree pt){
    if(pt has top) pt = pt.top;
    
    c = newCollector("spl", pt, splConfig());
    splPreCollectInitialization(pt, c);
    collect(pt, c);
    return newSolver(pt, c.run()).run();
}

TModel splTModelFromName(str mname, bool _){
    pt = parse(#start[Begin], |project://siwesprojectlang/src/main/rascal/<mname>.spl|).top;
    return splTModelForTree(pt);
}

test bool splTests() {
    return runTests([|project://siwesprojectlang/src/main/rascal/tests.ttl|], 
                     #start[Begin], 
                     TModel (Tree t) { return splTModelForTree(t); },
                     runName = "Spl");
}

// TModel syntaxModelForTree(Tree pt){
//     return collectAndSolve(pt);
// }

// test bool splTests() {
//     return runTests([|project://siwesprojectlang/src/main/rascal/tests.ttl|],
//                     #start[Begin],
//                     syntaxModelForTree,
//                     runName = "Spl");
// }