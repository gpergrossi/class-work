//
// Created by Gregary on 10/29/2015.
//

#ifndef ECE449_NETLIST_H
#define ECE449_NETLIST_H

#include "SyntaxModule.h"
#include "SimNetList.h"

SimNetList *create_netlist(const SyntaxModules &modules);
SimNetList *create_netlist(const SyntaxModule &module);

void print_netlist(std::ostream &stream, SimNetList const *netlist);
bool save_netlist(const std::string &out_filename, const SimNetList *netlist);

#endif //ECE449_NETLIST_H
