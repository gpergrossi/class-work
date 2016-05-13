//
// Created by Gregary on 10/29/2015.
//

#ifndef ECE449_SIMNETLIST_H
#define ECE449_SIMNETLIST_H


#include "SimComponent.h"
#include "SimNet.h"
#include <map>

class SimNetList {

public:
    SimNetList(std::string name) {
        module_type_ = name;
    }
    inline std::string get_module_type() const {
        return module_type_;
    }
    inline int get_num_nets() const {
        return (int) nets_.size();
    }

    inline std::vector<SimNet *>::const_iterator nets_begin() const {
        return nets_.begin();
    }
    inline std::vector<SimNet *>::const_iterator nets_end() const {
        return nets_.end();
    }

    inline int get_num_gates() const {
        return (int) gates_.size();
    }

    inline std::vector<SimComponent *>::const_iterator gates_begin() const {
        return gates_.begin();
    }
    inline std::vector<SimComponent *>::const_iterator gates_end() const {
        return gates_.end();
    }

    friend std::ostream& operator<<(std::ostream&, const SimNetList &);

protected:
    std::string module_type_;
    std::vector<SimNet *> nets_;
    std::vector<SimComponent *> gates_;
};


#endif //ECE449_SIMNETLIST_H
