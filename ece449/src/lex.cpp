#include <iostream>
#include <fstream>
#include <string>
#include <vector>

#include "LexToken.h"
#include "lex.h"
#include "definitions.h"

/**
 * LexToken Pattern struct representing a pattern for selecting a token.
 * If the first function of this pattern returns true for a character
 * in the EasyVL file, the pattern will be activated. Once activated,
 * a pattern will gather all following characters until the more function
 * returns false, at which point a token will be created using this
 * pattern's type.
 */
struct Lex_Token_Pattern {
    LexToken::TokenType type;
    bool (*first)(char);
    bool (*more)(char);
} ;
typedef std::vector<Lex_Token_Pattern> Lex_Token_Patterns;

const Lex_Token_Patterns &get_token_patterns();


/**
 * Save tokens to a file
 * Returns true if there were no errors
 */
bool save_tokens(const std::string &out_file, const LexTokens &tokens) {
    /* Open file for writing */
    std::ofstream output_file(out_file.c_str());
    if (!output_file) 
    {
        std::cerr << "Error writing to file '" << out_file << '\'' << std::endl;
        return false;
    }

    print_tokens(output_file, tokens);
    return true;
}

/**
 * Prints each token to the output stream with line returns after each
 */
void print_tokens(std::ostream &out_stream, const LexTokens &tokens) {
    for (LexTokens::const_iterator token = tokens.begin();
        token != tokens.end(); token++)
    {
        out_stream << (*token) << std::endl;
    }
}

/**
 * Reads tokens from the given EasyVL file name into the provided token vector.
 * 
 * Returns true if there were no errors.
 */
bool read_tokens(const std::string &evl_file, LexTokens &tokens) {
    
    /* Open file for reading */
    std::ifstream input_file(evl_file.c_str());
    if (!input_file) {
        std::cerr << "Cannot read file '" << evl_file << "'." << std::endl;
        return false;
    }

    /* Insure token vector is empty to begin */
    tokens.clear();

    /* Parse file line by line */
    std::string line;
    bool error;
    for (int line_num = 1; std::getline(input_file, line); line_num++) {
        error = !read_tokens_line(line_num, line, tokens);
        if (error) return false;
    }
   
    return true;
}

/**
 * Reads tokens from the given line of EasyVL text into the provided token vector.
 * LexTokens will record the line number provided for future debugging purposes.
 * The patterns argument should be a vector of patterns that will be applied
 * in order from beginning to end. The first pattern that matches will be used.
 * If no pattern matches, an 'unexpected character' error message is displayed.
 * 
 * Returns true if tokens were read without any problems, else false.
 */
bool read_tokens_line(int line_num, const std::string &line, LexTokens &tokens)
{
    for (size_t i = 0; i < line.size(); i++) {
        char ch = line[i];

        /* Check for comments */
        if (ch == '/') 
        {
            /* Report error if next character is not a slash */
            i++;
            if (i == line.size() || line[i] != '/') {
                std::cerr << "Error on line " << line_num;
                std::cerr << ": a single / is not allowed" << std::endl;
                return -1;
            }

            /* Skip the rest of the line by exiting the function */
            return true;
        }


        /* Skip WHITESPACE characters */
        if (is_whitespace(ch)) 
        {
            /* Continue to next character */
            continue;
        }


        /* Check match of any Lex_Token_Pattern */
        bool matched = false;
        Lex_Token_Patterns patterns = get_token_patterns();
        for (Lex_Token_Patterns::iterator pattern = patterns.begin();
             pattern != patterns.end(); pattern++)
        {
            if (!(*pattern).first(ch)) continue;
            
            /* First character of pattern matched, scan for more */
            size_t j;
            for (j = i+1 ; j < line.size(); j++) {
                if ((*pattern).more(line[j])) continue;
                break;
            }
            size_t length = j - i;
            
            /* Define new token */
            LexToken token((*pattern).type, line.substr(i, length), line_num, (int) i);

            /* Add token to token vector */
            tokens.push_back(token);

            /* Continue to next character */
            i += length - 1;
            matched = true;
            break;
        }
        if (matched) continue;
        
        std::cerr << "Error on line " << line_num;
        std::cerr << ": Unexpected character '";
        std::cerr << ch << '\'' << std::endl;
        return false;
    }
    
    return true;
}

/**
 * Definitions of the various pattern's non-simple predicates.
 */
bool single_pattern_more(char c) { return false; }
bool name_pattern_first(char c) { return is_alpha(c) || c == '_'; }
bool name_pattern_more(char c) { return is_alphanum(c) || c == '_' || c == '$'; }

/**
 * Creates the token patterns and fills the provided vector with them
 */
const Lex_Token_Patterns &get_token_patterns() {
    static Lex_Token_Patterns patterns;

    if (patterns.size() == 0) {
        /* Pattern for SINGLE */
        Lex_Token_Pattern single;
        single.type = LexToken::SINGLE;
        single.first = is_single;
        single.more = single_pattern_more;

        /* Pattern for NAME */
        Lex_Token_Pattern name;
        name.type = LexToken::NAME;
        name.first = name_pattern_first;
        name.more = name_pattern_more;

        /* Pattern for NUMBER */
        Lex_Token_Pattern number;
        number.type = LexToken::NUMBER;
        number.first = is_num;
        number.more = is_num;

        /* Add patterns to pattern vector */
        patterns.clear();
        patterns.push_back(single);
        patterns.push_back(name);
        patterns.push_back(number);
    }

    return patterns;
}


/**
 * Returns true if the character c is found in the string category.
 */
bool is_char_a(char c, std::string category) {
    if (c == '\0') return false;
    size_t loc = category.find_first_of(c);
    if (loc == std::string::npos) return false;
    return true;
}


/**
 * Returns true if the character is a syntactic SINGLE
 * It may be one of the following: ()[]:;,
 */
bool is_single(char c) {
    return is_char_a(c, "()[]:;,");
}

/**
 * Returns true if the character is one of the permitted whitespace.
 * It may be a space, tab, carriage return, or line feed
 */
bool is_whitespace(char c) {
    return is_char_a(c, " \t\r\n");
}

/**
 * Returns true if the character is a letter or number
 */
bool is_alphanum(char c) {
    return is_alpha(c) || is_num(c);
}

/**
 * Returns true if the character is a letter
 */
bool is_alpha(char c) {
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z');
}

/**
 * Returns true if the character is a digit, 0-9
 */
bool is_num(char c) {
    return (c >= '0' && c <= '9');
}


