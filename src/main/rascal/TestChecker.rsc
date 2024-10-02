module TestChecker

extend analysis::typepal::TestFramework;
extend Checker;
import Syntax;
import ParseTree;

TModel syntaxModelForTree(Tree pt){
    return collectAndSolve(pt, modelName = "spl");
}

TModel syntaxTModelFromLoc(loc code){
    pt = parse(#start[Begin], code);
    return collectAndSolve(pt);
}

test bool splTests() {
    return runTests([|project://siwesprojectlang/src/main/rascal/tests.spl|],
                    #SPL,
                    syntaxModelForTree,
                    runName = "Spl");
}

bool main() = splTests();

TModel syntaxTModelFromTree(Tree pt){
    return collectAndSolve(pt);
}