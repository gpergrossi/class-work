//
// Created by Gregary on 10/9/2015.
//

#include <assert.h>
#include "LexToken.h"

LexToken::LexToken(TokenType type, std::string text,
                         int line_num, int column_num) {
    assert(text.length() > 0);
    assert(type != SINGLE || text.length() == 1);

    type_ = type;
    text_ = text;
    line_num_ = line_num;
    column_num_ = column_num;
}

std::string get_token_type_name(LexToken::TokenType t) {
    switch (t) {
        case LexToken::NAME:     return "NAME";
        case LexToken::NUMBER:   return "NUMBER";
        case LexToken::SINGLE:   return "SINGLE";
        default:    assert(false);
    }
}

LexToken::TokenType LexToken::get_type() const { return type_; }
bool LexToken::is_name() const { return type_ == NAME; }
bool LexToken::is_name(std::string s) const { return type_ == NAME && text_.compare(s) == 0; }

bool LexToken::is_number() const { return type_ == NUMBER; }
bool LexToken::is_number(int min, int max) const {
    if (type_ != NUMBER) return false;
    int n = get_number();
    if (n < min || n > max) return false;
    return true;
}

bool LexToken::is_single() const { return type_ == SINGLE; }
bool LexToken::is_single(char c) const {
    return type_ == SINGLE && text_.length() == 1 && text_.at(0) == c;
}

std::string LexToken::get_text() const { return text_; }
int LexToken::get_line_num() const { return line_num_; }
int LexToken::get_column_num() const { return column_num_; }
int LexToken::get_number() const { return atoi(text_.c_str()); }

std::ostream &operator<<(std::ostream &stream, const LexToken &token) {
    return stream << get_token_type_name(token.type_) << std::string(" ") << token.text_;
}


