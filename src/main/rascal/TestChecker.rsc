module TestChecker

extend analysis::typepal::TestFramework;
extend Checker;
import Syntax;
import ParseTree;


TModel syntaxModelForTree(Tree pt){
    return collectAndSolve(pt);
}

test bool splTests() {
    return runTests([|project://siwesprojectlang/src/main/rascal/tests.spl|],
                    #start[Begin],
                    syntaxModelForTree,
                    runName = "Spl");
}