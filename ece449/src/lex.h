//
// Created by Gregary on 10/9/2015.
//

#ifndef ECE449_LEX_H
#define ECE449_LEX_H

#include <string>
#include "definitions.h"
#include "LexToken.h"

bool is_char_a(char c, std::string category);
bool is_single(char c);
bool is_whitespace(char c);
bool is_alphanum(char c);
bool is_alpha(char c);
bool is_num(char c);

bool read_tokens(const std::string &evl_file, LexTokens &tokens);
void print_tokens(std::ostream &out_stream, const LexTokens &tokens);
bool save_tokens(const std::string &out_file, const LexTokens &tokens);
bool read_tokens_line(int line_num, const std::string &line, LexTokens &tokens);

#endif //ECE449_LEX_H


