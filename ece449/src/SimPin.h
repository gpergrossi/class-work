//
// Created by Gregary on 10/29/2015.
//

#ifndef ECE449_SIMPIN_H
#define ECE449_SIMPIN_H


#include <stddef.h>
#include <vector>
#include <string>
#include <ostream>

class NetListBuilder;
class SimComponent;
class SimNet;

class SimPin {
    friend class NetListBuilder;
    friend class SimComponentBuilder;

public:
    enum PinDirection { IN, OUT };

    inline PinDirection get_direction() const { return dir_; }
    inline SimComponent *get_gate() const { return gate_; } // TODO: privacy?
    inline size_t get_pin_index() const { return pin_index_; }

    inline std::string get_bus_name() const { return bus_name; }
    inline int get_bus_lsb() const { return bus_lsb; }
    inline int get_bus_msb() const { return bus_msb; }

    inline int get_bus_width() const {
        return (int) nets_.size(); // Same as num_nets, provided for completeness
    }
    inline int get_num_nets() const {
        return (int) nets_.size();
    }
    inline std::vector<SimNet *>::const_iterator nets_begin() const {
        return nets_.begin();
    }
    inline std::vector<SimNet *>::const_iterator nets_end() const {
        return nets_.end();
    }

    friend std::ostream &operator<<(std::ostream&, const SimPin&);

private:
    SimComponent *gate_;
    size_t pin_index_;
    PinDirection dir_;

    std::string bus_name;
    int bus_lsb;
    int bus_msb;

    std::vector<SimNet *> nets_;
};


#endif //ECE449_SIMPIN_H
