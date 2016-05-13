//
// Created by Gregary on 10/29/2015.
//

#include <map>
#include <iostream>
#include <sstream>
#include "SimComponent.h"
#include "SyntaxWire.h"
#include "NetListBuilder.h"
#include "Simulation.h"
#include "definitions.h"

#define constructor(Type) \
    static SimComponentBuilder *construct (NetListBuilder *builder, const SyntaxComponent &cmpt) { \
        return new Type(builder, cmpt); \
    }

int hex_to_dec(char hex);
char dec_to_hex(int dec);

// *************************************** NOT GATE **********************************************

class Not : SimComponentBuilder {
private:
    SimPin *out;
    SimPin *in;
    Not(NetListBuilder *builder, const SyntaxComponent &cmpt) : SimComponentBuilder(builder, cmpt) {
        out = accept_pin(SimPin::OUT, 1, 1);
        in = accept_pin(SimPin::IN, 1, 1);
        assert_no_more_pins();
    }
public:
    constructor(Not)
    virtual void sim_init(Simulation *sim) {}
    virtual void sim_update(Simulation *sim) {
        Logic::Signal val = (*in->nets_begin())->get_value();
        net_iter net = out->nets_begin();
        sim->drive_net(this, *net, Logic::invert(val));
    }
    virtual void sim_clock(Simulation *sim) {
        Logic::Signal val = (*in->nets_begin())->get_value();
        if (val == Logic::HIGH_Z) {
            std::cerr << "Warning: HIGHZ driving logic gate at end of cycle";
        }
    }
};

// *************************************** BUFFER **********************************************
class Buf : SimComponentBuilder {
private:
    SimPin *out;
    SimPin *in;
    Buf(NetListBuilder *builder, const SyntaxComponent &cmpt) : SimComponentBuilder(builder, cmpt) {
        out = accept_pin(SimPin::OUT, 1, 1);
        in = accept_pin(SimPin::IN, 1, 1);
        assert_no_more_pins();
    }
public:
    constructor(Buf)
    virtual void sim_init(Simulation *sim) {}
    virtual void sim_update(Simulation *sim) {
        Logic::Signal val = (*in->nets_begin())->get_value();
        net_iter net = out->nets_begin();
        sim->drive_net(this, *net, val);
    }
    virtual void sim_clock(Simulation *sim) {
        Logic::Signal val = (*in->nets_begin())->get_value();
    }
};

// *************************************** D Flip Flop **********************************************

class Dff : SimComponentBuilder {
private:
    SimPin *out;
    SimPin *inD, *inCLOCK;
    Logic::Signal memory;
    Dff(NetListBuilder *builder, const SyntaxComponent &cmpt) : SimComponentBuilder(builder, cmpt) {
        out = accept_pin(SimPin::OUT, 1, 1);
        inD = accept_pin(SimPin::IN, 1, 1);
        inCLOCK = accept_pin(SimPin::IN, 1, 1);
        assert_no_more_pins();
        memory = Logic::LOW;
    }
public:
    constructor(Dff)
    virtual void sim_init(Simulation *sim) {}
    virtual void sim_update(Simulation *sim) {
        net_iter net = out->nets_begin();
        sim->drive_net(this, *net, memory);
    }
    virtual void sim_clock(Simulation *sim) {
        Logic::Signal old = memory;
        memory = (*inD->nets_begin())->get_value();
        sim->queue_update(this);
    }
};

// *************************************** EVL Input **********************************************

class Input : SimComponentBuilder {
private:
    std::istream *input;
    std::vector<SimPin *> outs;
    std::string hex_line;
    int transitions;
    Input(NetListBuilder *builder, const SyntaxComponent &cmpt) : SimComponentBuilder(builder, cmpt) {
        accept_pins(outs, SimPin::OUT, 1, MAX_BUS_WIDTH, 1, 1000);
        assert_no_more_pins();
        transitions = 0;
        hex_line = "0";
    }
public:
    constructor(Input)
    virtual void sim_init(Simulation *sim) {
        input = sim->register_input(name_);

        // Number of pins
        std::string line;
        std::getline(*input, line);
        std::istringstream iss(line);

        //std::cout << "Initializing '" << *this << "'..." << std::endl;
        //std::cout << "Read: \"" << line << "\"" << std::endl;

        char discard_char;
        int num_pins;
        iss >> num_pins;

        //std::cout << "Num = " << num_pins << std::endl;

        if (num_pins != outs.size()) {
            std::cerr << "Input pin count does not match number of pins for input device";
            std::cerr << " '" << *this << "'" << std::endl;
            exit(1);
        }

        // Width of each pin
        for (pin_iter pin = outs.begin(); pin != outs.end(); pin++) {
            int width = (*pin)->get_bus_width();

            int in_width;
            iss >> in_width;
            //std::cout << "Num = " << in_width << std::endl;

            if (iss.eof() && pin+1 != outs.end()) {
                std::cerr << "Unexpected end of line while reading input pin widths for device";
                std::cerr << " '" << *this << "'" << std::endl;
                exit(1);
            }

            if (width != in_width) {
                std::cerr << "Input pin width does not match width of pin for input device pin";
                std::cerr << " '" << *(*pin) << "'" << std::endl;
                std::cerr << "Input file: " << in_width << ", input gate: " << width << std::endl;
                exit(1);
            }
        }

        // Feed first values
        //std::cout << "Applying first iteration from input" << std::endl;
        this->sim_clock(sim);
    }
    virtual void sim_update(Simulation *sim) {
        std::istringstream iss(hex_line);

        int discard_int;
        iss >> discard_int;

        for (pin_iter pin = outs.begin(); pin != outs.end(); pin++) {
            std::string sub;
            iss >> sub; // Extract one word, whitespace separated
            set_pin_hex_string(sim, *pin, sub);
        }
    }
    virtual void sim_clock(Simulation *sim) {
        if (transitions <= 0) {
            if (!input->eof()) {
                std::getline(*input, hex_line);
            }
            std::istringstream iss(hex_line);
            iss >> transitions;
            // std::cout << "Applying signal '" << hex_line << "' for " << transitions << " iterations" << std::endl;
            sim->queue_update(this);
        }

        transitions--;
    }
};

// *************************************** EVL Output **********************************************

class Output : SimComponentBuilder {
private:
    std::ostream *output;
    std::vector<SimPin *> ins;
    Output(NetListBuilder *builder, const SyntaxComponent &cmpt) : SimComponentBuilder(builder, cmpt) {
        accept_pins(ins, SimPin::IN, 1, MAX_BUS_WIDTH, 1, 1000);
        assert_no_more_pins();
    }
public:
    constructor(Output)
    virtual void sim_init(Simulation *sim) {
        output = sim->register_output(name_);

        // Number of pins
        (*output) << ins.size() << std::endl;

        // Width of each pin
        for (pin_iter pin = ins.begin(); pin != ins.end(); pin++) {
            int width = (*pin)->get_bus_width();
            (*output) << width << std::endl;
        }
    }
    virtual void sim_update(Simulation *sim) {}
    virtual void sim_clock(Simulation *sim) {
        for (pin_iter pin = ins.begin(); pin != ins.end(); pin++) {
            (*output) << get_pin_hex_string(*pin);
            if (pin+1 != ins.end()) (*output) << " ";
        }
        (*output) << std::endl;
    }
};

// *************************************** EVL Zero **********************************************

class Zero : SimComponentBuilder {
private:
    std::vector<SimPin *> outs;
    Zero(NetListBuilder *builder, const SyntaxComponent &cmpt) : SimComponentBuilder(builder, cmpt) {
        accept_pins(outs, SimPin::OUT, 1, MAX_BUS_WIDTH, 1, 1000);
        assert_no_more_pins();
    }
public:
    constructor(Zero)
    virtual void sim_init(Simulation *sim) {}
    virtual void sim_update(Simulation *sim) {
        for (pin_iter pin = outs.begin(); pin != outs.end(); pin++) {
            (*pin)->nets_begin();
            for (net_iter net = (*pin)->nets_begin(); net != (*pin)->nets_end(); net++) {
                sim->drive_net(this, *net, Logic::LOW);
            }
        }
    }
    virtual void sim_clock(Simulation *sim) {}
};

// *************************************** EVL One **********************************************

class One : SimComponentBuilder {
private:
    std::vector<SimPin *> outs;
    One(NetListBuilder *builder, const SyntaxComponent &cmpt) : SimComponentBuilder(builder, cmpt) {
        accept_pins(outs, SimPin::OUT, 1, MAX_BUS_WIDTH, 1, 1000);
        assert_no_more_pins();
    }
public:
    constructor(One)
    virtual void sim_init(Simulation *sim) {}
    virtual void sim_update(Simulation *sim) {
        for (pin_iter pin = outs.begin(); pin != outs.end(); pin++) {
            (*pin)->nets_begin();
            for (net_iter net = (*pin)->nets_begin(); net != (*pin)->nets_end(); net++) {
                sim->drive_net(this, *net, Logic::HIGH);
            }
        }
    }
    virtual void sim_clock(Simulation *sim) {}
};

// *************************************** EVL Clock **********************************************

class Clock : SimComponentBuilder {
private:
    std::vector<SimPin *> outs;
    Clock(NetListBuilder *builder, const SyntaxComponent &cmpt) : SimComponentBuilder(builder, cmpt) {
        accept_pins(outs, SimPin::OUT, 1, MAX_BUS_WIDTH, 1, 1000);
        assert_no_more_pins();
    }
public:
    constructor(Clock)
    virtual void sim_init(Simulation *sim) {}
    virtual void sim_update(Simulation *sim) {}
    virtual void sim_clock(Simulation *sim) {}
};

// *************************************** Logic Operations **********************************************

/* Logic NAME Gate */
template<Logic::Signal (*op)(Logic::Signal, Logic::Signal)> class BoolOp : SimComponentBuilder {
private:
    SimPin *out;
    std::vector<SimPin *> ins;
    BoolOp(NetListBuilder *builder, const SyntaxComponent &cmpt) : SimComponentBuilder(builder, cmpt) {
        out = accept_pin(SimPin::OUT, 1, 1);
        accept_pins(ins, SimPin::IN, 1, 1, 1, 100);
        assert_no_more_pins();
    }
public:
    constructor(BoolOp)
    virtual void sim_init(Simulation *sim) {}
    virtual void sim_update(Simulation *sim) {
        pin_iter pin = ins.begin();
        Logic::Signal sig = (*(*pin)->nets_begin())->get_value();
        for (; pin != ins.end(); pin++) {
            Logic::Signal next = (*(*pin)->nets_begin())->get_value();
            sig = op(sig, next);
        }
        sim->drive_net(this, (*out->nets_begin()), sig);
    }
    virtual void sim_clock(Simulation *sim) {}
};



// *************************************** Tri-state Buffer **********************************

class Tris : SimComponentBuilder {
private:
    SimPin* out;
    SimPin* in;
    SimPin* en;
    Tris(NetListBuilder *builder, const SyntaxComponent &cmpt) : SimComponentBuilder(builder, cmpt) {
        out = accept_pin(SimPin::OUT, 1, 1);
        in = accept_pin(SimPin::IN, 1, 1);
        en = accept_pin(SimPin::IN, 1, 1);
        assert_no_more_pins();
    }
public:
    constructor(Tris)
    virtual void sim_init(Simulation *sim) {}
    virtual void sim_update(Simulation *sim) {
        Logic::Signal sig_en = (*en->nets_begin())->get_value();
        if (sig_en == Logic::HIGH) {
            Logic::Signal sig_in = (*in->nets_begin())->get_value();
            sim->drive_net(this, (*out->nets_begin()), sig_in);
        } else {
            sim->drive_net(this, (*out->nets_begin()), Logic::HIGH_Z);
        }

    }
    virtual void sim_clock(Simulation *sim) {}
};

// *************************************** Look-up Table **********************************

class Lut : SimComponentBuilder {
private:
    std::istream *input;
    SimPin* word;
    SimPin* address;
    std::vector<std::string> table;
    long last_address;
    Lut(NetListBuilder *builder, const SyntaxComponent &cmpt) : SimComponentBuilder(builder, cmpt) {
        word = accept_pin(SimPin::OUT, 1, MAX_BUS_WIDTH);
        address = accept_pin(SimPin::IN, 1, MAX_BUS_WIDTH);
        assert_no_more_pins();
        last_address = -1;
    }
public:
    constructor(Lut)
    virtual void sim_init(Simulation *sim) {
        input = sim->register_lut(this->get_name());

        // Number of pins
        std::string line;
        std::getline(*input, line);
        std::istringstream iss(line);

        //std::cout << "Initializing '" << *this << "'..." << std::endl;
        //std::cout << "Read: \"" << line << "\"" << std::endl;

        char discard_char;
        int word_width;
        int address_width;
        iss >> word_width;
        iss >> address_width;

        //std::cout << "Num = " << num_pins << std::endl;

        if (word->get_bus_width() != word_width) {
            std::cerr << "Error in initialization: word width does not match lut file for '";
            std::cerr << *this << "'" << std::endl;
            std::cerr << "lut file width: " << word_width << std::endl;
            std::cerr << "component pin width: " << word->get_bus_width() << std::endl;
            exit(1);
        }

        if (address->get_bus_width() != address_width) {
            std::cerr << "Error in initialization: address width does not match lut file for '";
            std::cerr << *this << "'" << std::endl;
            std::cerr << "lut file width: " << address_width << std::endl;
            std::cerr << "component pin width: " << address->get_bus_width() << std::endl;
            exit(1);
        }

        while (!input->eof()) {
            std::getline(*input, line);
            table.push_back(line);
        }
    }
    virtual void sim_update(Simulation *sim) {
        long address_value = get_pin_long(address);
        if (address_value == -1 || address_value == last_address) {
            return;
        }
        last_address = address_value;
        if (((size_t) address_value) >= table.size()) {
            std::cerr << "lut table access error. address not defined." << std::endl;
            return;
        }
        std::string word_value = table[(size_t) address_value];
        std::cout << "lut address changed to " << address_value;
        std::cout << ", value = " << word_value << std::endl;
        set_pin_hex_string(sim, word, word_value);
    }
    virtual void sim_clock(Simulation *sim) {}
};

/********************************************************************************************/

SimComponentBuilder::pin_constructor_t SimComponentBuilder::get_constructor(std::string type) {
    static std::map<std::string, SimComponentBuilder::pin_constructor_t> map;

    if (map.size() == 0) {
        map["not"] = Not::construct;
        map["evl_dff"] = Dff::construct;
        map["evl_output"] = Output::construct;
        map["evl_input"] = Input::construct;
        map["evl_zero"] = Zero::construct;
        map["evl_one"] = One::construct;
        map["evl_clock"] = Clock::construct;
        map["xor"] = BoolOp<Logic::Xor>::construct;
        map["and"] = BoolOp<Logic::And>::construct;
        map["or"] = BoolOp<Logic::Or>::construct;
        map["buf"] = Buf::construct;
        map["tris"] = Tris::construct;
        map["evl_lut"] = Lut::construct;
    }

    if (map.count(type) == 1) {
        return map[type];
    } else {
        return NULL;
    }
}

void SimComponentBuilder::assert_no_more_pins() {
    if (current_pin != end_of_pins) {
        std::cerr << "Component has too many pins for requirements of type" << std::endl;
        std::cerr << "in component '" << syntax_cmpt << "'" << std::endl;
        valid = false;
    }
}
int SimComponentBuilder::accept_pins(std::vector<SimPin *> &pins, SimPin::PinDirection dir,
                int minWidth, int maxWidth, int minPins, int maxPins)
{
    int pins_read = 0;
    for (; current_pin != end_of_pins;) {
        SimPin *pin = accept_pin(dir, minWidth, maxWidth);
        pins.push_back(pin);
        pins_read++;

        if (pins_read > maxPins) assert_no_more_pins();
    }

    if (pins_read < minPins) {
        std::cerr << "Component has too few pins for requirements of type" << std::endl;
        std::cerr << "in component '" << syntax_cmpt << "'" << std::endl;
        valid = false; return -1;
    }

    return pins_read;
}

SimPin *SimComponentBuilder::accept_pin(SimPin::PinDirection dir, int minWidth, int maxWidth) {
    if (current_pin == end_of_pins) {
        std::cerr << "Component has too few pins for requirements of type" << std::endl;
        std::cerr << "in component '" << syntax_cmpt << "'" << std::endl;
        valid = false; return NULL;
    }

    std::string wire_name = current_pin->get_name();
    const SyntaxWire *wire = builder->find_wire(wire_name);
    std::vector<SimNet *> bus_nets = builder->find_bus_nets(wire_name);

    if (wire == NULL) {
        std::cerr << "Pin '" << (*current_pin) << "' refers to undefined wire!" << std::endl;
        valid = false; return NULL;
    }
    if (bus_nets.size() == 0) {
        std::cerr << "Bus nets not found. Pin '" << (*current_pin);
        std::cerr << "' refers to undefined wire!" << std::endl;
        valid = false; return NULL;
    }

    int bus_lsb, bus_msb;

    // Check msb and lsb for validity against wire
    if (wire->get_width() == 1) {
        if (current_pin->get_bus_lsb() == -1 && current_pin->get_bus_msb() == -1) {
            bus_lsb = 0;
            bus_msb = 0;
        } else {
            std::cerr << "Pin '" << (*current_pin) << "' specifies bus on non-bus wire!" << std::endl;
            valid = false; return NULL;
        }
    } else if (current_pin->get_bus_lsb() == -1) {
        if (current_pin->get_bus_msb() == -1) {
            bus_lsb = 0;
            bus_msb = wire->get_width()-1;
        } else {
            bus_msb = current_pin->get_bus_msb();
            bus_lsb = bus_msb;
            if (bus_msb >= wire->get_width() || bus_msb < 0) {
                std::cerr << "Pin '" << (*current_pin);
                std::cerr << "' specifies bus out of range for wire!" << std::endl;
                valid = false; return NULL;
            }
        }
    } else if (current_pin->get_bus_msb() != -1) {
        bus_lsb = current_pin->get_bus_lsb();
        bus_msb = current_pin->get_bus_msb();
        if (bus_msb >= wire->get_width() || bus_msb < bus_lsb || bus_lsb < 0) {
            std::cerr << "Pin '" << (*current_pin);
            std::cerr << "' specifies bus out of range for wire!" << std::endl;
            valid = false; return NULL;
        }
    } else {
        std::cout << "SYNTAX parsing error: Pin specifies lsb but not msb!";
        std::cerr << std::endl;
        valid = false; return NULL;
    }
    if (bus_lsb > bus_msb) {
        std::cerr << "Code Error, bus_lsb > bus_msb";
        valid = false; return NULL;
    }

    int msb = current_pin->get_bus_msb();
    int lsb = current_pin->get_bus_lsb();
    int width = msb - lsb + 1;

    int index = (int) this->pins_.size();

    if (width < minWidth) {
        std::cerr << "Width of pin " << index << " is too small for pin requirements type" << std::endl;
        std::cerr << "in component '" << syntax_cmpt << "'" << std::endl;
        valid = false; return NULL;
    }
    if (width < minWidth) {
        std::cerr << "Width of pin " << index << " is too large for pin requirements type" << std::endl;
        std::cerr << "in component '" << syntax_cmpt << "'" << std::endl;
        valid = false; return NULL;
    }

    SimPin *sim_pin = new SimPin();
    sim_pin->gate_ = this;
    sim_pin->pin_index_ = (size_t) index;
    sim_pin->bus_name = current_pin->get_name();
    sim_pin->bus_lsb = lsb;
    sim_pin->bus_msb = msb;
    sim_pin->dir_ = dir;

    // std::cout << "  Pin \"" << type_ << ":" << index << "\"";
    pins_.push_back(sim_pin);
    // std::cout << " added." << std::endl;

    // TODO nothing prevents overlaps
    for (int bus_index = bus_lsb; bus_index <= bus_msb; bus_index++) {
        // std::cout << "  > ";

        SimNet *net = bus_nets[bus_index];

        // Connect net to pin (index doesn't matter)
        net->connections_.push_back(sim_pin);
        if (sim_pin->dir_ == SimPin::OUT) {
            net->num_drivers_++;
        }
        // std::cout << "Connected to net \"" << net->get_name() << "\"" << std::endl;

        // Connect pin to net (indices 0 to K-1)
        sim_pin->nets_.push_back(net);
    }

    current_pin++;
    return sim_pin;
}

SimComponentBuilder *SimComponentBuilder::construct (NetListBuilder *builder, const SyntaxComponent &component) {
    std::string type = component.get_type();
    pin_constructor_t ctor = get_constructor(type);

    if (ctor == NULL) {
        std::cerr << "Cannot find module of type \"" << type << "\"." << std::endl;
        SimComponentBuilder *cmpt = new SimComponentBuilder(builder, component);
        cmpt->valid = false;
        return cmpt;
    }

    return ctor(builder, component);
}

SimComponentBuilder::SimComponentBuilder(NetListBuilder *builder, const SyntaxComponent &cmpt) {
    valid = true;
    this->builder = builder;
    syntax_cmpt = cmpt;
    current_pin = cmpt.pins_begin();
    end_of_pins = cmpt.pins_end();
    type_ = cmpt.get_type();
    name_ = cmpt.get_name();
}

std::ostream &operator<<(std::ostream &stream, const SimComponent &comp) {
    std::flush(std::cout);
    stream << comp.type_;
    if (comp.name_.length() > 0) {
        stream << " " << comp.name_;
    }
    return stream;
}

const char hex_digits[17] = "0123456789ABCDEF";
const char hex_digits_low[17] = "0123456789abcdef";

int hex_to_dec(char hex) {
    hex = (char) toupper(hex); // To Upper
    for (int i = 0; i < 16; i++) {
        if (hex_digits[i] == hex) return i;
        if (hex_digits_low[i] == hex) return i;
    }
    return -1;
}
char dec_to_hex(int dec) {
    if (dec < 0 || dec > 15) return 'X';
    return hex_digits[dec];
}

void SimComponentBuilder::set_pin_hex_string(Simulation *sim, SimPin *pin, const std::string &hex) {
    // Print pin net values as minimal hex string
    int buffer = 0, bit_idx = 0, bit = 0;
    for (net_iter net = pin->nets_begin(); net != pin->nets_end(); net++) {

        if (bit_idx % 4 == 0) {
            if ((bit_idx/4) < hex.length()) {
                int idx = (int) (hex.length() - (bit_idx / 4) - 1);
                // std::cout << "Hex: \"" << hex << "\", char " << idx;
                buffer = hex_to_dec(hex[idx]);
                // std::cout << ", val = " << buffer << ", bit_idx = " << bit_idx << std::endl;
            } else {
                buffer = 0;
            }
        }

        bit = (buffer >> (bit_idx % 4)) & 1;
        // std::cout << "bit " << bit << std::endl;
        sim->drive_net(this, *net, bit ? Logic::HIGH : Logic::LOW);

        bit_idx++;
    }
}

std::string SimComponentBuilder::get_pin_hex_string(SimPin *pin) {
    // Print pin net values as minimal hex string
    std::string hex_str;
    int buffer = 0, bit_idx = 0, bit = 0;
    for (net_iter net = pin->nets_begin(); net != pin->nets_end(); net++) {

        if ((*net)->get_value() == Logic::HIGH) {
            bit = 1;
        } else if ((*net)->get_value() == Logic::LOW) {
            bit = 0;
        } else {
            std::cerr << "Warning: Unexpected value ";
            std::cerr << Logic::signal_string((*net)->get_value());
            std::cerr << " for pin '" << (*pin) << "'" << std::endl;
            exit(1);
        }

        buffer |= (bit << (bit_idx % 4));

        bit_idx++;
        if (bit_idx % 4 == 0 || net+1 == pin->nets_end()) {
            hex_str = dec_to_hex(buffer) + hex_str;
            buffer = 0;
        }
    }
    return hex_str;
}

long SimComponentBuilder::get_pin_long(SimPin *pin) {
    // Print pin net values as minimal hex string
    long buffer = 0, bit = 1;
    int index = 0;
    for (net_iter net = pin->nets_begin(); net != pin->nets_end(); net++) {

        if ((*net)->get_value() == Logic::HIGH) {
            buffer |= bit;
        } else if ((*net)->get_value() == Logic::LOW) {
            buffer &= ~bit;
        } else {
            return -1;
        }

        index++;
        bit <<= 1;

        if (index > 64) {
            std::cerr << "Warning: Lut address larger than 64 bits!" << std::endl;
        }
    }
    return buffer;
}