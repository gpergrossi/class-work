#ifndef ECE449_LOGIC_H
#define ECE449_LOGIC_H

#include <string>

namespace Logic {

    enum Signal {
        UNKNOWN, HIGH, LOW, HIGH_Z, ERROR
    };

    Signal invert(Signal s);

    Signal combine(Signal a, Signal b);

    std::string signal_string(Signal a);

    Signal Or(Signal a, Signal b);
    Signal And(Signal a, Signal b);
    Signal Xor(Signal a, Signal b);

}

#endif //ECE449_LOGIC_H