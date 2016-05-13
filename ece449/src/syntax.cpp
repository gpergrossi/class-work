//
// Created by Gregary on 10/9/2015.
//

#include <string>
#include <iostream>
#include <fstream>
#include "syntax.h"
#include "SyntaxWire.h"
#include "SyntaxModule.h"

#define SWITCH_STATE(ARG) { state = ARG;  token_iterator++;  handled = true; }
#define EXPECTED(ARG)   { std::cerr << "Expected token " << ARG << " at line "; \
                        std::cerr << token.get_line_num() << ", column "; \
                        std::cerr << token.get_column_num() << std::endl; \
                        return false; }

bool parse_component_statement(SyntaxModule &module, LexTokens::const_iterator &token_iterator) {
    DEBUG(SYNTAX) { std::cout << "Beginning COMPONENT statement" << std::endl; }

    enum STATE { INIT, TYPE, NAME, PINS, PIN_NAME, BUS, BUS_MSB, BUS_COLON, BUS_LSB, BUS_DONE, PINS_DONE, DONE };
    STATE state = INIT;
    SyntaxComponent component;
    SyntaxPin pin;

    while (state != DONE) {
        LexToken token = *token_iterator;
        DEBUG(SYNTAX) { std::cout << "> " << token << std::endl; }
        bool handled = false;
        switch (state) {
            case INIT:
                if (token.is_name()) {
                    component.set_type(token.get_text());
                    SWITCH_STATE(TYPE);
                }
                if (!handled) EXPECTED("NAME");
                break;
            case TYPE:
                if (token.is_name()) {
                    component.set_name(token.get_text());
                    SWITCH_STATE(NAME);
                }
                if (token.is_single('(')) SWITCH_STATE(PINS);
                if (!handled) EXPECTED("NAME or '('");
                break;
            case NAME:
                if (token.is_single('(')) SWITCH_STATE(PINS);
                if (!handled) EXPECTED("'('");
                break;
            case PINS:
                if (token.is_name()) {
                    pin.set_wire_name(token.get_text());
                    pin.set_bus_msb(-1);
                    pin.set_bus_lsb(-1);
                    SWITCH_STATE(PIN_NAME);
                }
                if (!handled) EXPECTED("NAME");
                break;
            case PIN_NAME:
                if (token.is_single(',')) {
                    component.add_pin(pin);
                    SWITCH_STATE(PINS);
                }
                if (token.is_single(')')) {
                    component.add_pin(pin);
                    SWITCH_STATE(PINS_DONE);
                }
                if (token.is_single('[')) SWITCH_STATE(BUS);
                if (!handled)  EXPECTED("',', ')', or '['");
                break;
            case BUS:
                if (token.is_number(0,MAX_BUS_WIDTH)) {
                    pin.set_bus_msb(token.get_number());
                    SWITCH_STATE(BUS_MSB);
                }
                if (!handled) EXPECTED("NUMBER");
                break;
            case BUS_MSB:
                if (token.is_single(':')) SWITCH_STATE(BUS_COLON);
                if (token.is_single(']')) SWITCH_STATE(BUS_DONE);
                if (!handled) EXPECTED("':' or ']'");
                break;
            case BUS_COLON:
                if (token.is_number(0,pin.get_bus_msb())) {
                    pin.set_bus_lsb(token.get_number());
                    SWITCH_STATE(BUS_LSB);
                }
                if (!handled) EXPECTED("'0'");
                break;
            case BUS_LSB:
                if (token.is_single(']')) SWITCH_STATE(BUS_DONE);
                if (!handled) EXPECTED("']'");
                break;
            case BUS_DONE:
                if (token.is_single(')')) {
                    component.add_pin(pin);
                    SWITCH_STATE(PINS_DONE);
                }
                if (token.is_single(',')) {
                    component.add_pin(pin);
                    SWITCH_STATE(PINS);
                }
                if (!handled) EXPECTED("',' or ')'");
                break;
            case PINS_DONE:
                if (token.is_single(';')) SWITCH_STATE(DONE);
                if (!handled) EXPECTED("';'");
                break;
            case DONE:
                // Make the compiler happy
                break;
        }
    }

    module.add_component(component);

    DEBUG(SYNTAX) { std::cout << "Successfully Finished COMPONENT statement" << std::endl; }
    return true;
}

bool parse_wire_statement(SyntaxModule &module, LexTokens::const_iterator &token_iterator)
{
    DEBUG(SYNTAX) { std::cout << "Beginning WIRE statement" << std::endl; }

    enum STATE { INIT, WIRE, BUS, BUS_MSB, BUS_COLON, BUS_LSB, BUS_DONE, WIRE_NAME, WIRES, DONE };
    STATE state = INIT;
    SyntaxWire wire;

    while (state != DONE) {
        LexToken token = *token_iterator;
        DEBUG(SYNTAX) { std::cout << "> " << token << std::endl; }
        bool handled = false;
        switch (state) {
            case INIT:
                if (token.is_name("wire")) SWITCH_STATE(WIRE);
                if (!handled) EXPECTED("'wire'");
                break;
            case WIRE:
                if (token.is_single('[')) SWITCH_STATE(BUS);
            case BUS_DONE:
            case WIRES:
                if (token.is_name()) {
                    wire.set_name(token.get_text());
                    module.add_wire(wire);
                    SWITCH_STATE(WIRE_NAME);
                }
                if (!handled) {
                    if (state == WIRE) EXPECTED("'[' or NAME");
                    EXPECTED("NAME");
                }
                break;
            case BUS:
                if (token.is_number(0,MAX_BUS_WIDTH)) {
                    wire.set_width(token.get_number()+1);
                    SWITCH_STATE(BUS_MSB);
                }
                if (!handled) EXPECTED("NUMBER");
                break;
            case BUS_MSB:
                if (token.is_single(':')) SWITCH_STATE(BUS_COLON);
                if (!handled) EXPECTED("':'");
                break;
            case BUS_COLON:
                if (token.is_number(0,0)) SWITCH_STATE(BUS_LSB);
                if (!handled) EXPECTED("'0'");
                break;
            case BUS_LSB:
                if (token.is_single(']')) SWITCH_STATE(BUS_DONE);
                if (!handled) EXPECTED("']'");
                break;
            case WIRE_NAME:
                if (token.is_single(',')) SWITCH_STATE(WIRES);
                if (token.is_single(';')) SWITCH_STATE(DONE);
                if (!handled) EXPECTED("',' or ';'");
                break;
            case DONE:
                // Make the compiler happy
                break;
        }
    }

    DEBUG(SYNTAX) { std::cout << "Successfully Finished WIRE statement" << std::endl; }
    return true;
}

bool parse_module(SyntaxModule &module, LexTokens::const_iterator &token_iterator)
{
    DEBUG(SYNTAX) { std::cout << "Beginning MODULE statement" << std::endl; }

    enum STATE { INIT, MODULE, NAME, CONTENT, DONE };
    STATE state = INIT;
    module.clear();

    while (state != DONE) {
        LexToken token = *token_iterator;
        DEBUG(SYNTAX) { std::cout << "> " << token << std::endl; }
        bool handled = false;
        switch (state) {
            case INIT:
                if (token.is_name("module")) SWITCH_STATE(MODULE);
                if (!handled) EXPECTED("'module'");
                break;
            case MODULE:
                if (token.is_name()) {
                    module.set_type(token.get_text());
                    SWITCH_STATE(NAME);
                }
                if (!handled) EXPECTED("NAME");
                break;
            case NAME:
                if (token.is_single(';')) SWITCH_STATE(CONTENT);
                if (!handled) EXPECTED("';'");
                break;
            case CONTENT:
                if (token.is_name("endmodule")) {
                    state = DONE;
                    handled = true;
                } else if (token.is_name("wire")) {
                    handled = parse_wire_statement(module, token_iterator);
                } else {
                    handled = parse_component_statement(module, token_iterator);
                }
                if (!handled) EXPECTED("'endmodule', 'wire', or COMPONENT");
                break;
            case DONE:
                // Make the compiler happy
                break;
        }
    }

    DEBUG(SYNTAX) { std::cout << "Successfully Finished MODULE statement" << std::endl; }
    return true;
}

bool parse_syntax(const LexTokens &tokens, SyntaxModules &modules) {
    SyntaxModule module;

    for (LexTokens::const_iterator token_iterator = tokens.begin();
         token_iterator != tokens.end(); token_iterator++)
    {
        DEBUG(SYNTAX) { std::cout << "> " << (*token_iterator) << std::endl; }

        bool success = parse_module(module, token_iterator);
        if (success) {
            modules.push_back(module);
            DEBUG(SYNTAX) {
                std::cout << "Added module " << module.get_name() << " [";
                std::cout << modules.size() << "]" << std::endl;
            }
        } else {
            std::cerr << "Error parsing module" << std::endl;
            std::flush(std::cerr);
            exit(1);
        }
    }
    return true;
}

void print_module(std::ostream &stream, const SyntaxModule &module) {
    stream << "module " << module.get_name() << std::endl;

    const SyntaxWires wires = module.get_wires();
    stream << "wires " << wires.size() << std::endl;
    for (SyntaxWires::const_iterator wire = wires.begin();
            wire != wires.end(); wire++)
    {
        stream << "  wire " << wire->get_name() << " ";
        stream << wire->get_width() << std::endl;
    }

    const SyntaxComponents components = module.get_components();
    stream << "components " << components.size() << std::endl;
    for (SyntaxComponents::const_iterator component = components.begin();
         component != components.end(); component++)
    {
        stream << "  component " << component->get_type();
        if (component->get_name().compare("") != 0) {
            stream << " " << component->get_name();
        }
        const SyntaxPins pins = component->get_pins();
        stream << " " << pins.size() << std::endl;

        for (SyntaxPins::const_iterator pin = pins.begin();
             pin != pins.end(); pin++)
        {
            stream << "    pin " << pin->get_name();
            if (pin->get_bus_msb() != -1) {
                stream << " " << pin->get_bus_msb();
            }
            if (pin->get_bus_lsb() != -1) {
                stream << " " << pin->get_bus_lsb();
            }
            stream << std::endl;
        }
    }

}

void print_modules(std::ostream &stream,  const SyntaxModules &modules) {
    for (SyntaxModules::const_iterator module = modules.begin();
         module != modules.end(); module++)
    {
        print_module(stream, *module);
    }
}

bool save_modules(const std::string &out_filename, const SyntaxModules &modules) {
    /* Open file for writing */
    std::ofstream output_file(out_filename.c_str());
    if (!output_file)
    {
        std::cerr << "Error writing to file '" << out_filename << '\'' << std::endl;
        return false;
    }
    print_modules(output_file, modules);
    return true;
}

