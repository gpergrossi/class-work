//
// Created by Gregary on 10/9/2015.
//

#ifndef ECE449_TOKEN_H
#define ECE449_TOKEN_H

#include <string>
#include <vector>
#include <stdlib.h>

/* LexToken class representing one EasyVL token */
class LexToken {
public:
    enum TokenType { NAME, NUMBER, SINGLE };

    LexToken(TokenType type, std::string text, int line_num, int column_num);

    TokenType get_type() const;
    bool is_name() const;
    bool is_name(std::string s) const;

    bool is_number() const;
    bool is_number(int min, int max) const;

    bool is_single() const;
    bool is_single(char c) const;

    std::string get_text() const;
    int get_line_num() const;
    int get_column_num() const;
    int get_number() const;

    friend std::ostream& operator<<(std::ostream&, const LexToken &);

private:
    TokenType type_;
    std::string text_;
    int line_num_;
    int column_num_;

    LexToken() { };
};

typedef std::vector<LexToken> LexTokens;

#endif //ECE449_TOKEN_H


