//
// Created by Gregary on 10/10/2015.
//

#ifndef ECE449_MODULE_H
#define ECE449_MODULE_H

#include <vector>
#include <string>
#include "SyntaxWire.h"
#include "SyntaxComponent.h"

class SyntaxModule {
public:
    SyntaxModule();
    void add_wire(const SyntaxWire &wire);
    void add_component(const SyntaxComponent &component);
    void set_type(std::string type);
    void clear();

    std::string get_name() const;
    const std::vector<SyntaxWire> get_wires() const;
    const std::vector<SyntaxComponent> get_components() const;

private:
    std::string type_;
    std::vector<SyntaxWire> wires_;
    std::vector<SyntaxComponent> components_;
};

typedef std::vector<SyntaxModule> SyntaxModules;

#endif //ECE449_MODULE_H


