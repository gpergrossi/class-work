//
// Created by Gregary on 10/11/2015.
//

#ifndef ECE449_PIN_H
#define ECE449_PIN_H

#include <ostream>
#include <string>
#include <vector>

class SyntaxPin {
    // TODO Add line number and column number
    // TODO make bus lsb and msb use a typedef instead of int
private:
    std::string wire_name_;
    int bus_lsb_, bus_msb_;
public:
    SyntaxPin();
    void set_wire_name(std::string name);
    void set_bus_lsb(int lsb);
    void set_bus_msb(int msb);
    std::string get_name() const;
    int get_bus_lsb() const;
    int get_bus_msb() const;

    friend std::ostream& operator<<(std::ostream&, const SyntaxPin&);
};

typedef std::vector<SyntaxPin> SyntaxPins;


#endif //ECE449_PIN_H


