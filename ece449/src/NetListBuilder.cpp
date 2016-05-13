//
// Created by Gregary on 11/6/2015.
//

#include "NetListBuilder.h"
#include "definitions.h"
#include <iostream>
#include <sstream>

NetListBuilder::NetListBuilder(std::string name) : SimNetList(name) { }

bool NetListBuilder::add_wire(const SyntaxWire &wire) {
    std::string name = wire.get_name();

    if (net_map_.find(name) != net_map_.end()) {
        std::cout << "ERROR: Wire by the name of \"" << name;
        std::cout << "ERROR: \" already exists!" << std::endl;
        return false;
    }

    // std::cout << "Adding wire \"" << wire.get_name() << "\"" << std::endl;

    // Add all of wire's nets to the wire map, net map, and net list
    wire_map_[name] = &wire;
    int width = wire.get_width();

    {
        std::vector<SimNet *> stuff;
        stuff.reserve((size_t) width);
        net_map_[name] = stuff;
    }

    if (width > 1) {
        for (int i = 0; i < width; i++) {
            std::stringstream ss;
            ss << name << "[" << i << "]";
            std::string netname = ss.str();

            // Create net object
            SimNet *net = new SimNet(netname);

            // std::cout << "  New net \"" << netname << "\"";

            std::map<std::string, std::vector<SimNet *> >::iterator match = net_map_.find(name);
            match->second.push_back(net);
            nets_.push_back(net);
            // std::cout << " added." << std::endl;
        }
    } else {
        SimNet *net = new SimNet(name);

        // std::cout << "  New net \"" << name << "\"" << std::endl;

        std::map<std::string, std::vector<SimNet *> >::iterator match = net_map_.find(name);
        match->second.push_back(net);

        nets_.push_back(net);
    }

    return true;
}

const SyntaxWire *NetListBuilder::find_wire(std::string name) const {
    int count = (int) wire_map_.count(name);
    if (count != 1) {
        return NULL;
    } else {
        return wire_map_.find(name)->second;
    }
}

std::vector<SimNet *> NetListBuilder::find_bus_nets(std::string name) const {
    int count = (int) net_map_.count(name);
    if (count != 1) {
        return std::vector<SimNet *>();
    } else {
        return net_map_.find(name)->second;
    }
}

bool NetListBuilder::add_component(const SyntaxComponent &component) {

    // std::cout << "Adding component \"" << component.get_type() << " " << component.get_name() << "\"" << std::endl;

    const SyntaxPins pins = component.get_pins();

    // std::cout << pins.size() << " pins" << std::endl;
    // std::flush(std::cout);

    SimComponentBuilder *sim_component = SimComponentBuilder::construct(this, component);
    if (!sim_component->valid) {
        std::cerr << "sim component invalid ->" << std::endl;
        return false;
    }

    gates_.push_back(sim_component);
    return true;
}
