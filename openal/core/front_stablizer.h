#ifndef CORE_FRONT_STABLIZER_H
#define CORE_FRONT_STABLIZER_H

#include <array>
#include <memory>

#include "almalloc.h"
#include "bufferline.h"
#include "filters/splitter.h"
#include "flexarray.h"


class FrontStablizer {
    explicit FrontStablizer(const size_t numchans) : ChannelFilters{numchans} { }

public:
    alignas(16) std::array<float,BufferLineSize> MidDirect{};
    alignas(16) std::array<float,BufferLineSize> Side{};
    alignas(16) std::array<float,BufferLineSize> Temp{};

    BandSplitter MidFilter;
    alignas(16) FloatBufferLine MidLF{};
    alignas(16) FloatBufferLine MidHF{};

    al::FlexArray<BandSplitter,16> ChannelFilters;

    static auto Create(size_t numchans) -> std::unique_ptr<FrontStablizer>
    { return std::unique_ptr<FrontStablizer>{new(FamCount{numchans}) FrontStablizer{numchans}}; }

    DEF_FAM_NEWDEL(FrontStablizer, ChannelFilters)
};

#endif /* CORE_FRONT_STABLIZER_H */
