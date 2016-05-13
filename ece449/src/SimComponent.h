//
// Created by Gregary on 10/29/2015.
//

#ifndef ECE449_SIMGATE_H
#define ECE449_SIMGATE_H


#include <string>
#include <ostream>
#include <vector>
#include "SyntaxComponent.h"
#include "SimPin.h"

class Simulation;
class NetListBuilder;

class SimComponent {
    friend class SimComponentBuilder;

public:
    inline std::string get_name() const  { return name_; }
    inline std::string get_type() const { return type_; }

    typedef std::vector<SimPin *>::const_iterator pin_iterator;
    inline int get_num_pins() const { return (int) pins_.size(); }
    inline pin_iterator pins_begin() const { return pins_.begin(); }
    inline pin_iterator pins_end() const { return pins_.end(); }

    /* Use to request an output slot or memory slot from the simulation manager */
    virtual void sim_init(Simulation *) {}

    /* Use to do combinational logic updates (called multiple times per clock cycle) */
    virtual void sim_update(Simulation *) {}

    /* Use to update clocked changes such as flip-flops (called at end of each cycle) */
    virtual void sim_clock(Simulation *) {}

    friend std::ostream &operator<<(std::ostream&, const SimComponent&);

protected:
    std::string type_;
    std::string name_;
    std::vector<SimPin *> pins_;

    SimComponent() {}
};

class SimComponentBuilder : public SimComponent {
    friend class NetListBuilder;

protected:
    bool valid;
    NetListBuilder *builder;
    SyntaxComponent syntax_cmpt;
    SyntaxComponent::pin_iterator current_pin;
    SyntaxComponent::pin_iterator end_of_pins;

    typedef SimComponentBuilder* (*pin_constructor_t)(NetListBuilder *builder, const SyntaxComponent &cmpt);
    static pin_constructor_t get_constructor(std::string type);
    static SimComponentBuilder *construct (NetListBuilder *builder, const SyntaxComponent &component);

    typedef std::vector<SimPin *>::const_iterator pin_iter;
    typedef std::vector<SimNet *>::const_iterator net_iter;

    SimComponentBuilder(NetListBuilder *builder, const SyntaxComponent &cmpt);

    SimPin *accept_pin(SimPin::PinDirection dir, int minWidth, int maxWidth);
    int accept_pins(std::vector<SimPin *>&, SimPin::PinDirection,
                    int minWidth, int maxWidth, int minPins, int maxPins);

    /**
     * Converts the nets connected to this pin to a hex string with the
     * minimal number of hex characters (can be an odd number). Any pins
     * with a value other than High or Low will cause an error.
     */
    std::string get_pin_hex_string(SimPin *pin);

    /**
     * Converts the nets connected to this pin to a long value. Any pins
     * with a value other than High or Low will cause an error.
     */
    long get_pin_long(SimPin *pin);

    /**
    * Sets the nets on this pin to High or Low based on the least
    * significant bits of the provided hex string.
    */
    void set_pin_hex_string(Simulation *sim, SimPin *pin, const std::string &hex);

    void assert_no_more_pins();
};

#endif //ECE449_SIMGATE_H
