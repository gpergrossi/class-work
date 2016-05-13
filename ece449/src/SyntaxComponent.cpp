//
// Created by Gregary on 10/11/2015.
//

#include <iostream>
#include "SyntaxComponent.h"

SyntaxComponent::SyntaxComponent() {
    type_ = "";
    name_ = "";
    pins_.clear();
}

void SyntaxComponent::set_type(std::string type) {
    type_ = type;
}

void SyntaxComponent::set_name(std::string name) {
    name_ = name;
}

void SyntaxComponent::add_pin(SyntaxPin &pin) {
    pins_.push_back(pin);
}


std::string SyntaxComponent::get_type() const {
    return type_;
}

std::string SyntaxComponent::get_name() const {
    return name_;
}

const SyntaxPins SyntaxComponent::get_pins() const {
    return pins_;
}

std::ostream& operator<<(std::ostream &stream, const SyntaxComponent &cmp) {
    stream << cmp.type_;
    if (cmp.name_.length() > 0) {
        stream << " " << cmp.name_;
    }
    return stream;
}

