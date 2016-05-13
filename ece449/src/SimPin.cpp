//
// Created by Gregary on 10/29/2015.
//

#include "SimPin.h"

std::ostream &operator<<(std::ostream &, const SimComponent &); // Defined in SimComponent.cpp

std::ostream &operator<<(std::ostream &stream, const SimPin &pin) {
    stream << (*pin.get_gate()) << ":" << pin.get_pin_index();
    return stream;
}