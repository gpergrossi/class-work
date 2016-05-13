//
// Created by Gregary on 10/11/2015.
//

#include "SyntaxPin.h"

SyntaxPin::SyntaxPin() {
    wire_name_ = "";
    bus_lsb_ = -1;
    bus_msb_ = -1;
}

void SyntaxPin::set_wire_name(std::string name) {
    wire_name_ = name;
}

void SyntaxPin::set_bus_lsb(int lsb) {
    bus_lsb_ = lsb;
}

void SyntaxPin::set_bus_msb(int msb) {
    bus_msb_ = msb;
}

std::string SyntaxPin::get_name() const {
    return wire_name_;
}

int SyntaxPin::get_bus_lsb() const {
    return bus_lsb_;
}

int SyntaxPin::get_bus_msb() const {
    return bus_msb_;
}

std::ostream& operator<<(std::ostream &stream, const SyntaxPin &pin) {
    stream << pin.wire_name_;
    if (pin.bus_msb_ != -1) stream << " " << pin.bus_msb_;
    if (pin.bus_lsb_ != -1) stream << " " << pin.bus_lsb_;
    return stream;
}