//
// Created by Gregary on 11/20/2015.
//

#ifndef ECE449_SIMULATION_H
#define ECE449_SIMULATION_H

#include <ostream>
#include <istream>
#include <vector>
#include <set>
#include "SimNetList.h"

#define MAX_COMBINATIONAL_LOGIC_ITERATIONS 2000

class SimNetList;

class Simulation {
public:
    Simulation(std::string evl_filename);

    std::ostream *register_output(std::string component_name);
    std::istream *register_input(std::string component_name);
    std::istream *register_lut(std::string component_name);

    void drive_net(const SimComponent *driver, SimNet *net, Logic::Signal sig);
    void queue_update(SimComponent *driver);

    void simulate(int transitions);

    inline bool is_valid() const { return valid; }
    inline const SimNetList *get_netlist() const { return netlist_; }

    ~Simulation();

private:
    void queue_updates(SimNet *net);

    bool valid;
    std::string evl_filename_;
    SimNetList *netlist_;
    std::vector<std::ofstream *> outputs_;
    std::vector<std::ifstream *> inputs_;

    int sim_iteration;
    std::set<SimComponent *> *sim_gates;
    std::set<SimComponent *> *sim_gates_next;

    typedef std::vector<SimPin *>::const_iterator pin_iter;
    typedef std::vector<SimNet *>::const_iterator net_iter;
    typedef std::vector<SimComponent *>::const_iterator gate_iter;
};


#endif //ECE449_SIMULATION_H
