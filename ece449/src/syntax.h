//
// Created by Gregary on 10/9/2015.
//

#ifndef ECE449_SYNTAX_H
#define ECE449_SYNTAX_H

#include <string>
#include "LexToken.h"
#include "definitions.h"
#include "SyntaxModule.h"

bool parse_syntax(const LexTokens &tokens, std::vector<SyntaxModule> &modules);

void print_module(std::ostream &stream, const SyntaxModule &module);

void print_modules(std::ostream &stream,  const SyntaxModules &modules);

bool save_modules(const std::string &out_filename, const SyntaxModules &modules);

#endif //ECE449_SYNTAX_H


