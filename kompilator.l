%option noyywrap
%option yylineno
%{
 
 
#include <string>
#include <iostream>
#include <stdlib.h>
#include <cstring>
#include "types.h"
#include "kompilator.tab.h"

extern YYSTYPE yylval;
extern void yyerror(char const *);
  
%}

%%
[ \t\n]+ ;

\[[^\]]*\] ;

[0-9]+ {
    yylval.number =  atoll(yytext);
    return NUM;
}

[_a-z]+ {
    yylval.string = new std::string(yytext);
    return PIDENTIFIER;
}

";" {
    return SEMICOLON;
}

":" {
    return COLON;
}

DECLARE {
    return VAR;
}

IN {
    return KW_BEGIN;
}

END {
    return END;
}

READ {
    return READ;
}

WRITE {
    return WRITE;
}

IF {
    return IF;
}

THEN {
    return THEN;
}

ELSE {
    return ELSE;
}

ENDIF {
    return ENDIF;
}

WHILE {
    return WHILE;
}

DO {
    return DO;
}

ENDDO {
    return ENDDO;
}

ENDWHILE {
    return ENDWHILE;
}

FOR {
    return FOR;
}

FROM {
    return FROM;
}

TO {
    return TO;
}

DOWNTO {
    return DOWNTO;
}

ENDFOR {
    return ENDFOR;
}

"(" {
    return L_BR;
}

")" {
    return R_BR;
}

":=" {
    return ASSIGN;
}

"+" {
    return OPERATION_PLUS;
}

"-" {
    return OPERATION_MINUS;
}

"*" {
    return OPERATION_MULT;
}

"/" {
    return OPERATION_DIV;
}

"%" {
    return OPERATION_MOD;
}

"=" {
    return OPERATION_EQ;
}

"!=" {
    return OPERATION_NEQ;
}

"<" {
    return OPERATION_LT;
}

"<=" {
    return OPERATION_LE;
}

">" {
    return OPERATION_GT;
}

">=" {
    return OPERATION_GE;
}

. {
    std::string errorHandler = "niewłaściwy znak ";
    errorHandler += yytext;
    yyerror(errorHandler.c_str());
}
%%
