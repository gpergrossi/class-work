//
// Created by Gregary on 10/9/2015.
//

#include <iostream>
#include <fstream>
#include <vector>

#include "Simulation.h"
#include "netlist.h"

/* Main Function */
int main(int argc, char *argv[]) {

    /* Sanitize input */
    if (argc < 2)
    {
        std::cerr << "You should provide a file name." << std::endl;
        return -1;
    }
    std::string filename = argv[1];

    std::cout << "Building..." << std::endl;
    Simulation *sim = new Simulation(filename);
    if (!sim->is_valid()) {
        std::cerr << "simulation invalid" << std::endl;
        exit(-1);
    }

    // const SimNetList *netlist = sim->get_netlist();
    // std::cout << std::endl << "Netlist:" << std::endl;
    // print_netlist(std::cout, netlist);
    // std::cout << std::endl;


    std::cout << "Simulating..." << std::endl;
    sim->simulate(1000);
    std::cout << "Done!" << std::endl;

    exit(0);
}

