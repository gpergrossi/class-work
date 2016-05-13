//
// Created by Gregary on 10/11/2015.
//

#ifndef ECE449_COMPONENT_H
#define ECE449_COMPONENT_H

#include <string>
#include <vector>
#include "SyntaxPin.h"

class SyntaxComponent {
private:
    std::string type_;              // Required
    std::string name_;              // Could be name or left as ""
    std::vector<SyntaxPin> pins_;   // 0 or more pins

public:
    SyntaxComponent();
    void set_type(std::string type);
    void set_name(std::string name);

    typedef std::vector<SyntaxPin>::const_iterator pin_iterator;
    inline int get_num_pins() const { return pins_.size(); }
    inline pin_iterator pins_begin() const { return pins_.begin(); }
    inline pin_iterator pins_end() const { return pins_.end(); }

    void add_pin(SyntaxPin &pin);   // TODO deprecated

    std::string get_type() const;
    std::string get_name() const;
    const std::vector<SyntaxPin> get_pins() const;

    friend std::ostream& operator<<(std::ostream&, const SyntaxComponent&);
};

typedef std::vector<SyntaxComponent> SyntaxComponents;

#endif //ECE449_COMPONENT_H


