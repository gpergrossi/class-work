#include "Logic.h"

namespace Logic {

    Signal invert(Signal s) {
        switch (s) {
            case HIGH:
                return LOW;
            case LOW:
                return HIGH;
            default:
                return s;
        }
    }

    Signal combine(Signal a, Signal b) {
        if (a == UNKNOWN) return b;
        if (b == UNKNOWN) return a;
        if (a == HIGH_Z) return b;
        if (b == HIGH_Z) return a;
        return ERROR;
    }

    std::string signal_string(Signal a) {
        switch (a) {
            case LOW: return "LOW";
            case HIGH: return "HIGH";
            case HIGH_Z: return "HIGH_Z";
            case UNKNOWN: return "UNKNOWN";
        }
    }

    Signal Or(Signal a, Signal b) {
        if (a == UNKNOWN) return UNKNOWN;
        if (b == UNKNOWN) return UNKNOWN;
        if (a == HIGH_Z) return UNKNOWN;
        if (b == HIGH_Z) return UNKNOWN;
        if (a == HIGH) return HIGH;
        if (b == HIGH) return HIGH;
        return LOW;
    }

    Signal And(Signal a, Signal b) {
        if (a == UNKNOWN) return UNKNOWN;
        if (b == UNKNOWN) return UNKNOWN;
        if (a == HIGH_Z) return UNKNOWN;
        if (b == HIGH_Z) return UNKNOWN;
        if (a == LOW) return LOW;
        if (b == LOW) return LOW;
        return HIGH;
    }

    Signal Xor(Signal a, Signal b) {
        if (a == UNKNOWN) return UNKNOWN;
        if (b == UNKNOWN) return UNKNOWN;
        if (a == HIGH_Z) return UNKNOWN;
        if (b == HIGH_Z) return UNKNOWN;
        if (a == b) return LOW;
        return HIGH;
    }

}