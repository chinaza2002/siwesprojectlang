module LanguageServer

import ParseTree;
import util::Reflective;
import util::LanguageServer;
import Syntax;

import Prelude;

set[LanguageService] siwesProjectLangContribs() = {
    parser(parser(#start[Begin]))
};

void setupIde() {
    registerLanguage(
        language(
            pathConfig(srcs = [|std:///|, |project://siwesprojectlang/src|]),
            "SPL Grammar",
            "spl",
            "LanguageServer",
            "siwesProjectLangContribs"
        )
    );
}