//
// Created by Gregary on 10/10/2015.
//

#ifndef ECE449_WIRE_H
#define ECE449_WIRE_H

#include <string>
#include <vector>

class SyntaxWire {
private:
    int width_;
    std::string name_;
public:
    SyntaxWire();
    void set_name(std::string name);
    void set_width(int width);

    std::string get_name() const;
    int get_width() const;
};

typedef std::vector<SyntaxWire> SyntaxWires;

#endif //ECE449_WIRE_H


