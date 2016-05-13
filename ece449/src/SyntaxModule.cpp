//
// Created by Gregary on 10/10/2015.
//

#include "SyntaxModule.h"

SyntaxModule::SyntaxModule() {
    clear();
}

void SyntaxModule::add_wire(const SyntaxWire &wire) {
    wires_.push_back(wire);
};

void SyntaxModule::add_component(const SyntaxComponent &component) {
    components_.push_back(component);
};

void SyntaxModule::set_type(std::string type) {
    type_ = type;
};

void SyntaxModule::clear() {
    type_ = "";
    wires_.clear();
    components_.clear();
};

std::string SyntaxModule::get_name() const {
    return type_;
}

const SyntaxWires SyntaxModule::get_wires() const {
    return wires_;
}

const SyntaxComponents SyntaxModule::get_components() const {
    return components_;
}

