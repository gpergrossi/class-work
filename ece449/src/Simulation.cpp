//
// Created by Gregary on 11/20/2015.
//

#include <iostream>
#include <fstream>
#include "Simulation.h"
#include "lex.h"
#include "syntax.h"
#include "netlist.h"

Simulation::Simulation(std::string evl_filename) {
    sim_iteration = -1;

    /* Extract tokens from file */
    LexTokens tokens;
    bool success = read_tokens(evl_filename, tokens);
    if (!success) {
        valid = false;
        std::cerr << "netlist invalid ->" << std::endl;
        return;
    }

    /* Read statements */
    SyntaxModules modules;
    success = parse_syntax(tokens, modules);
    if (!success) {
        valid = false;
        std::cerr << "netlist invalid ->" << std::endl;
        return;
    }

    /* Convert to NetList */
    SimNetList *netlist = create_netlist(modules);

    if (netlist == NULL) {
        valid = false;
        std::cerr << "netlist invalid ->" << std::endl;
        return;
    }

    evl_filename_ = evl_filename;
    netlist_ = netlist;
    valid = true;

    sim_iteration = 1;
    sim_gates = new std::set<SimComponent *>();
    sim_gates_next = new std::set<SimComponent *>();
}

Simulation::~Simulation() {
    for (std::vector<std::ofstream *>::iterator file = outputs_.begin();
        file != outputs_.end(); file++)
    {
        (*file)->close();
        delete *file;
    }

    for (std::vector<std::ifstream *>::iterator file = inputs_.begin();
         file != inputs_.end(); file++)
    {
        (*file)->close();
        delete *file;
    }
}

std::ostream *Simulation::register_output(std::string component_name) {
    std::string out_filename = evl_filename_+"."+component_name+".evl_output";
    std::ofstream *output_file = new std::ofstream(out_filename.c_str());
    if (! *output_file) {
        std::cerr << "Error openning file '" << out_filename << "' for writing" << std::endl;
    } else {
        std::cout << "File created for writing '" << out_filename << "'" << std::endl;
        outputs_.push_back(output_file);
    }

    return output_file;
}

std::istream *Simulation::register_input(std::string component_name) {
    std::string in_filename = evl_filename_+"."+component_name+".evl_input";
    std::ifstream *input_file = new std::ifstream(in_filename.c_str());
    if (! *input_file) {
        std::cerr << "Error openning file '" << in_filename << "' for reading" << std::endl;
    } else {
        std::cout << "File opened for reading '" << in_filename << "'" << std::endl;
        inputs_.push_back(input_file);
    }

    return input_file;
}

std::istream *Simulation::register_lut(std::string component_name) {
    std::string in_filename = evl_filename_+"."+component_name+".evl_lut";
    std::ifstream *input_file = new std::ifstream(in_filename.c_str());
    if (! *input_file) {
        std::cerr << "Error openning file '" << in_filename << "' for reading" << std::endl;
    } else {
        std::cout << "File opened for reading '" << in_filename << "'" << std::endl;
        inputs_.push_back(input_file);
    }

    return input_file;
}

void Simulation::queue_update(SimComponent *gate) {
    if (sim_gates_next->count(gate) == 0) {
        // std::cout << "Update queued for gate '" << *gate << "'" << std::endl;
        sim_gates_next->insert(gate);
    }
}

void Simulation::queue_updates(SimNet *net) {
    for (pin_iter pin = net->connections_begin(); pin != net->connections_end(); pin++) {
        if ((*pin)->get_direction() != SimPin::IN) {
            // std::cout << "Net change does NOT affect gate '" << (*(*pin)->get_gate()) << "'" << std::endl;
            continue;
        } else {
            // std::cout << "Net change DOES affect gate '" << (*(*pin)->get_gate()) << "'" << std::endl;
            queue_update((*pin)->get_gate());
        }
    }
}

void Simulation::drive_net(const SimComponent *driver, SimNet *net, Logic::Signal sig) {
    int i = 0;
    for (pin_iter pin = net->connections_begin(); pin != net->connections_end(); pin++) {
        if ((*pin)->get_direction() == SimPin::IN) continue;
        if ((*pin)->get_gate() == driver) {
            net->signals_[i] = sig;
            // std::cout << " vector " << i << std::endl;
            return;
        }
        i++;
    }
    std::cout << "driver " << *driver << " net " << *net << " signal ";
    std:: cout << Logic::signal_string(sig) << " no vector" << std::endl;
}

void Simulation::simulate(int transitions) {
    std::cout << std::endl << "=== Initialization ===" << std::endl << std::endl;

    // Initialize gates
    for (gate_iter gate = netlist_->gates_begin(); gate != netlist_->gates_end(); gate++ ) {
        (*gate)->sim_init(this);
        sim_gates->insert(*gate);
    }

    // Initialize nets
    for (net_iter net = netlist_->nets_begin(); net != netlist_->nets_end(); net++) {
        (*net)->initialize(); // Allocate space for drivers in net
    }

    std::set<SimComponent *> *swap;
    int final_iter = sim_iteration+transitions;

    std::cout << std::endl << "=== Simulation ===" << std::endl << std::endl;
    for (; sim_iteration < final_iter; sim_iteration++) {
        std::cout << "Iteration " << sim_iteration << ": " << std::endl;
        std::flush(std::cout);

        // Process all gates until no feedback
        int comb_iters = 0;
        while (sim_gates->size() > 0 && comb_iters < MAX_COMBINATIONAL_LOGIC_ITERATIONS) {

            std::cout << sim_gates->size() << " gate updates, ";
            // std::cout << "Processing active gates... (" << comb_iters << ")" << std::endl;
            for (std::set<SimComponent *>::iterator gate = sim_gates->begin(); gate != sim_gates->end(); gate++) {
                (*gate)->sim_update(this);
            }

            /*
            std::cout << "Current gates: ";
            for (std::set<SimComponent *>::iterator gate = sim_gates->begin(); gate != sim_gates->end(); gate++) {
                std::cout << "'" << *(*gate) << "' ";
            }
            std::cout << std::endl;

            std::cout << "Future gates: ";
            for (std::set<SimComponent *>::iterator gate = sim_gates_next->begin(); gate != sim_gates_next->end(); gate++) {
                std::cout << "'" << *(*gate) << "' ";
            }
            std::cout << std::endl;
            //*/

            // Update signals
            int state_changes = 0;
            for (net_iter net = netlist_->nets_begin(); net != netlist_->nets_end(); net++) {
                if ((*net)->num_drivers_ == 0) continue;
                int i = 0;
                Logic::Signal old = (*net)->signal_;
                Logic::Signal sig = (*net)->signals_[i++];

                // std::cout << (*net)->num_drivers_ << " drivers" << std::endl;
                for (; i < (*net)->num_drivers_; i++) {
                    sig = Logic::combine(sig, (*net)->signals_[i]);
                }

                (*net)->signal_ = sig;
                if (sig != old) {
                    state_changes++;
                    //std::cout << "net '" << *(*net) << "' move to state ";
                    //std::cout << Logic::signal_string(sig) << std::endl;
                    //std::cout << ".";
                    queue_updates(*net);
                }
            }
            //std::cout << std::endl;

            if (state_changes > 0) {
                std::cout << state_changes << " state changes" << std::endl;
            } else {
                //std::cout << "no changes" << std::endl;
            }
            std::cout << std::endl;

            // Swap next and current lists, clear new next list
            swap = sim_gates;
            sim_gates = sim_gates_next;
            sim_gates_next = swap;
            sim_gates_next->clear();
            comb_iters++;

        }

        // Check for unknowns, update gates that output to a net driven by multiple sources
        /*
        for (net_iter net = netlist_->nets_begin(); net != netlist_->nets_end(); net++ ) {
            Logic::Signal sig = (*net)->get_value();
            if (sig == Logic::UNKNOWN) {
                //std::cout << "Warning: Net " << *(*net) << " unknown at end of cycle." << std::endl;
            }
        }
        */

        int state_changes = 0;
        for (net_iter net = netlist_->nets_begin(); net != netlist_->nets_end(); net++) {
            if ((*net)->num_drivers_ == 0) continue;
            int i = 0;
            Logic::Signal old = (*net)->signal_;
            Logic::Signal sig = (*net)->signals_[i++];

            // std::cout << (*net)->num_drivers_ << " drivers" << std::endl;
            for (; i < (*net)->num_drivers_; i++) {
                sig = Logic::combine(sig, (*net)->signals_[i]);
                if (sig == Logic::ERROR) {
                    std::cout << "ERROR: contention on net '" << *(*net) << "'" << std::endl;
                }
            }
        }

        // Clock all gates
        for (gate_iter gate = netlist_->gates_begin(); gate != netlist_->gates_end(); gate++ ) {
            (*gate)->sim_clock(this);
            //queue_update(*gate);
        }

        // Swap next and current lists, clear new next list
        swap = sim_gates;
        sim_gates = sim_gates_next;
        sim_gates_next = swap;
        sim_gates_next->clear();
    }
}