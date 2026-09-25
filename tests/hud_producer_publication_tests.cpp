#include "hud_producer_publication.h"
#include <initializer_list>
int main() {
    using namespace w3vr::hud_publication;
    for (uint32_t eye : {0u, 1u}) {
        bool submitted = false;
        if (!ready(true, eye, 41) || ready(submitted, eye, 42)) return 1;
        for (int consumer = 0; consumer < 8; ++consumer) {
            if ((ready(submitted, eye, 42) ? 42 : 41) != 41) return 2;
        }
        if (same_capture(7, 43, 7, 42) || same_capture(8, 42, 7, 42)) return 3;
        if (!same_capture(7, 42, 7, 42)) return 4;
        submitted = true;
        if (!ready(submitted, eye, 42)) return 5;
        if (ready(true, UINT32_MAX, 0) || ready(true, eye, 0)) return 6;
    }
    return 0;
}
