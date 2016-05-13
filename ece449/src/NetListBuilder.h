//
// Created by Gregary on 11/6/2015.
//

#ifndef ECE449_NETLISTBUILDER_H
#define ECE449_NETLISTBUILDER_H

#include "SimNetList.h"
#include "SimNet.h"
#include "SyntaxComponent.h"
#include "SyntaxWire.h"
#include <map>

class NetListBuilder : public SimNetList {

public:
    NetListBuilder(std::string name);

    bool add_wire(const SyntaxWire &wire);
    bool add_component(const SyntaxComponent &cmpt);

    const SyntaxWire *find_wire(std::string) const;
    std::vector<SimNet *> find_bus_nets(std::string) const;

private:
    std::map<std::string, const SyntaxWire *> wire_map_;
    std::map<std::string, std::vector<SimNet *> > net_map_;

};


#endif //ECE449_NETLISTBUILDER_H
