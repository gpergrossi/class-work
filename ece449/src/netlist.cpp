//
// Created by Gregary on 10/29/2015.
//

#include <map>
#include <ostream>
#include <iostream>
#include <fstream>
#include "netlist.h"
#include "NetListBuilder.h"

SimNetList *create_netlist(const SyntaxModules &modules) {
    const SyntaxModule top = modules[0];
    return create_netlist(top);
}

SimNetList *create_netlist(const SyntaxModule &module) {

    NetListBuilder *netListBuilder = new NetListBuilder(module.get_name());

    const SyntaxWires syntax_wires = module.get_wires();

    for (SyntaxWires::const_iterator syntax_wire = syntax_wires.begin();
         syntax_wire != syntax_wires.end(); syntax_wire++)
    {
        bool success = netListBuilder->add_wire(*syntax_wire);
        if (!success) {
            std::cerr << "failed to add wire to netlist" << std::endl;
            return NULL;
        }
    }

    const SyntaxComponents syntax_components = module.get_components();

    for (SyntaxComponents::const_iterator syntax_component = syntax_components.begin();
            syntax_component != syntax_components.end(); syntax_component++)
    {
        bool success = netListBuilder->add_component(*syntax_component);
        if (!success) {
            std::cerr << "failed to add component to netlist ->" << std::endl;
            return NULL;
        }
    }

    return netListBuilder;

}

void print_netlist(std::ostream &stream, SimNetList const *netlist) {
    stream << *netlist;
}

bool save_netlist(const std::string &out_filename, const SimNetList *netlist) {
    /* Open file for writing */
    std::ofstream output_file(out_filename.c_str());
    if (!output_file)
    {
        std::cerr << "Error writing to file '" << out_filename << '\'' << std::endl;
        return false;
    }
    print_netlist(output_file, netlist);
    return true;
}

