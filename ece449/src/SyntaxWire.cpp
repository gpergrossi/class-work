//
// Created by Gregary on 10/10/2015.
//

#include "SyntaxWire.h"

SyntaxWire::SyntaxWire() {
    name_ = "";
    width_ = 1;
}

void SyntaxWire::set_name(std::string name) {
    name_ = name;
}

void SyntaxWire::set_width(int width) {
    width_ = width;
}

std::string SyntaxWire::get_name() const {
    return name_;
}

int SyntaxWire::get_width() const {
    return width_;
}

