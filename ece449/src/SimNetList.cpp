//
// Created by Gregary on 10/29/2015.
//

#include <ostream>
#include "SimNetList.h"

std::ostream &operator<<(std::ostream &stream, const SimNetList &netlist) {

    stream << "module " << netlist.get_module_type() << std::endl;
    std::flush(stream);

    stream << "nets " << netlist.get_num_nets() << std::endl;
    std::flush(stream);

    typedef std::vector<SimNet *>::const_iterator Nets_iter;
    typedef std::vector<SimPin *>::const_iterator Pins_iter;
    typedef std::vector<SimComponent *>::const_iterator Component_iter;

    for (Nets_iter net = netlist.nets_begin();
            net != netlist.nets_end(); net++)
    {
        stream << "  net " << (*net)->get_name() << " ";
        stream << (*net)->get_num_pins() << std::endl;

        for (Pins_iter pin = (*net)->connections_begin();
                pin != (*net)->connections_end(); pin++)
        {
            stream << "    " << (*pin)->get_gate()->get_type();
            std::string name = (*pin)->get_gate()->get_name();
            if (name.length() != 0) {
                stream << " " << name;
            }
            stream << " " << (*pin)->get_pin_index() << std::endl;
        }
    }

    stream << "components " << netlist.get_num_gates() << std::endl;

    for (Component_iter component = netlist.gates_begin();
        component != netlist.gates_end(); component++)
    {
        stream << "  component " << (*component)->get_type();
        std::string name = (*component)->get_name();
        if (name.length() != 0) {
            stream << " " << name;
        }
        stream << " " << (*component)->get_num_pins() << std::endl;

        for (Pins_iter pin = (*component)->pins_begin();
                pin != (*component)->pins_end(); pin++)
        {
            stream << "    pin " << (*pin)->get_num_nets();
            for (Nets_iter net = (*pin)->nets_begin();
                    net != (*pin)->nets_end(); net++)
            {
                stream << " " << (*net)->get_name();
            }
            stream << std::endl;
        }
    }

    return stream;
}
