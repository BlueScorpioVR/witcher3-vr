#include "reshade_overlay_policy.h"

#include <cassert>

int main() {
    using w3vr::reshade_overlay::effective_engine_menu_state;

    assert(effective_engine_menu_state(-1, false) == -1);
    assert(effective_engine_menu_state(0, false) == 0);
    assert(effective_engine_menu_state(1, false) == 1);

    assert(effective_engine_menu_state(-1, true) == 0);
    assert(effective_engine_menu_state(0, true) == 0);
    assert(effective_engine_menu_state(1, true) == 0);
    return 0;
}
