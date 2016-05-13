//
// Created by Gregary on 10/29/2015.
//

#include "SimNet.h"

SimNet::SimNet(std::string name) {
    name_ = name;
    signal_ = Logic::UNKNOWN;
    num_drivers_ = 0;
}

std::string SimNet::get_name() const {
    return name_;
}

std::vector<SimPin *>::const_iterator SimNet::connections_begin() const {
    return connections_.begin();
}

std::vector<SimPin *>::const_iterator SimNet::connections_end() const {
    return connections_.end();
}

int SimNet::get_num_pins() const {
    return (int) connections_.size();
}

Logic::Signal SimNet::get_value() const {
    return signal_;
}

void SimNet::initialize() {
    //std::cout << "initializing '" << (*this) << "' with " << num_drivers_ << " drivers" << std::endl;
    //std::flush(std::cout);
    signals_.reserve(num_drivers_);
    for (int i = 0; i < num_drivers_; i++) {
        signals_[i] = Logic::UNKNOWN;
    }
}

std::ostream &operator<<(std::ostream &stream, SimNet &net) {
    stream << net.name_;
    return stream;
}