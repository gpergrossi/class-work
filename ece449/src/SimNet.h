//
// Created by Gregary on 10/29/2015.
//

#ifndef ECE449_NET_H
#define ECE449_NET_H


#include <string>
#include <vector>
#include <iostream>
#include <stdlib.h>
#include "Logic.h"

class SimPin;
class SimComponent;

class SimNet {
    friend class SimComponentBuilder;
    friend class NetListBuilder;
    friend class Simulation;

public:
    std::string get_name() const;
    std::vector<SimPin *>::const_iterator connections_begin() const;
    std::vector<SimPin *>::const_iterator connections_end() const;
    int get_num_pins() const;

    Logic::Signal get_value() const;

    friend std::ostream &operator<<(std::ostream &stream, SimNet &net);

private:
    SimNet(std::string name);

    std::string name_;
    Logic::Signal signal_;
    std::vector<Logic::Signal> signals_;
    int num_drivers_;
    std::vector<SimPin*> connections_;

    void initialize();
};


#endif //ECE449_NET_H
