#ifndef CORE_BSINC_TABLES_H
#define CORE_BSINC_TABLES_H

#include <array>
#include <span>

#include "bsinc_defs.h"
#include "opthelpers.h"

struct BSincTable {
    float scaleBase, scaleRange;
    std::array<unsigned int,BSincScaleCount> m;
    std::array<unsigned int,BSincScaleCount> filterOffset;
    std::span<const float> Tab;
};

DECL_HIDDEN extern constinit const BSincTable gBSinc12;
DECL_HIDDEN extern constinit const BSincTable gBSinc24;
DECL_HIDDEN extern constinit const BSincTable gBSinc48;

#endif /* CORE_BSINC_TABLES_H */
