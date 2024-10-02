module CommonLex

extend lang::std::Layout;

lexical Id = ([a-z A-Z][a-z A-Z 0-9]* !>> [a-z A-Z 0-9]) \ Keywords;

lexical Boolean = "true" | "false";

lexical Integer = [0-9]+ !>> [0-9];

lexical String = [\"] ![\"]* [\"];

keyword Keywords = "true" | "false" | "if" | "else" |
                 "function" | "int" | "bool" |"str" | "while"
                 | "return"| "class" | "extends" | "for" | "in" | "do"
                 | "var" | "try" | "catch" | "finally"| "break" | "continue" 
                 | "switch" | "case" | "default" ;