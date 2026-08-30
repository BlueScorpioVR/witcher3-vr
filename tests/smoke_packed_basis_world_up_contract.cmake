if(NOT DEFINED DXGI_PROXY_SOURCE)
    message(FATAL_ERROR "DXGI_PROXY_SOURCE is required")
endif()

file(READ "${DXGI_PROXY_SOURCE}" DXGI_PROXY_TEXT)

set(REQUIRED_FRAGMENTS
    "[PERF:SMOKE-PACKED-BASIS-WORLD-UP V1514]"
    "float3 signed_horizontal = -float3("
    "float3 signed_vertical = vertex.tc5.xyz;"
    "float horizontal_extent = abs(dot(delta, signed_horizontal));"
    "float vertical_extent = abs(dot(delta, signed_vertical));"
    "desired_h_base * (horizontal_sign * horizontal_extent)"
    "world_up * (vertical_sign * vertical_extent)"
    "vertex.tc1.w = dot(cameraRows[10], float4(new_world, 1.0));"
    "vertex.position.x += %.9g * vertex.position.w;"
    "vertex.position.y += %.9g * vertex.position.w;")

foreach(REQUIRED_FRAGMENT IN LISTS REQUIRED_FRAGMENTS)
    string(FIND "${DXGI_PROXY_TEXT}" "${REQUIRED_FRAGMENT}" FOUND_INDEX)
    if(FOUND_INDEX EQUAL -1)
        message(FATAL_ERROR
            "Missing V1514 packed-basis smoke fragment: ${REQUIRED_FRAGMENT}")
    endif()
endforeach()

set(FORBIDDEN_FRAGMENTS
    "float3 edge_a ="
    "float3 edge_b ="
    "horizontal_denominator"
    "vertical_denominator"
    "horizontal_coordinate"
    "vertical_coordinate")

foreach(FORBIDDEN_FRAGMENT IN LISTS FORBIDDEN_FRAGMENTS)
    string(FIND "${DXGI_PROXY_TEXT}" "${FORBIDDEN_FRAGMENT}" FOUND_INDEX)
    if(NOT FOUND_INDEX EQUAL -1)
        message(FATAL_ERROR
            "Superseded smoke edge reconstruction remains: ${FORBIDDEN_FRAGMENT}")
    endif()
endforeach()

# Compile the exact embedded source after substituting neutral optical-centre
# constants for the two snprintf placeholders. This catches HLSL errors at
# build/test time instead of waiting for PSO creation in game.
set(SMOKE_SHADER_BEGIN "cbuffer GeometryCamera : register(b1) {")
set(SMOKE_SHADER_END [=[)", center_x, center_y);]=])
string(FIND "${DXGI_PROXY_TEXT}" "${SMOKE_SHADER_BEGIN}" SMOKE_BEGIN_INDEX)
if(SMOKE_BEGIN_INDEX EQUAL -1)
    message(FATAL_ERROR "Embedded smoke geometry shader start was not found")
endif()
string(SUBSTRING "${DXGI_PROXY_TEXT}" ${SMOKE_BEGIN_INDEX} -1 SMOKE_SHADER_TAIL)
string(FIND "${SMOKE_SHADER_TAIL}" "${SMOKE_SHADER_END}" SMOKE_END_INDEX)
if(SMOKE_END_INDEX EQUAL -1)
    message(FATAL_ERROR "Embedded smoke geometry shader end was not found")
endif()
string(SUBSTRING "${SMOKE_SHADER_TAIL}" 0 ${SMOKE_END_INDEX} SMOKE_SHADER_TEXT)
string(REPLACE "%.9g" "0.0" SMOKE_SHADER_TEXT "${SMOKE_SHADER_TEXT}")

file(GLOB DXC_CANDIDATES
    "C:/Program Files (x86)/Windows Kits/10/bin/*/x64/dxc.exe")
if(NOT DXC_CANDIDATES)
    message(FATAL_ERROR "Windows SDK dxc.exe was not found")
endif()
list(SORT DXC_CANDIDATES COMPARE NATURAL ORDER DESCENDING)
list(GET DXC_CANDIDATES 0 DXC_EXECUTABLE)

set(SMOKE_HLSL_PATH
    "${CMAKE_CURRENT_BINARY_DIR}/v1514-smoke-packed-basis-world-up.hlsl")
set(SMOKE_DXIL_PATH
    "${CMAKE_CURRENT_BINARY_DIR}/v1514-smoke-packed-basis-world-up.dxil")
file(WRITE "${SMOKE_HLSL_PATH}" "${SMOKE_SHADER_TEXT}")
execute_process(
    COMMAND "${DXC_EXECUTABLE}"
        -E main -T gs_6_0 -O3
        -Fo "${SMOKE_DXIL_PATH}"
        "${SMOKE_HLSL_PATH}"
    RESULT_VARIABLE DXC_RESULT
    OUTPUT_VARIABLE DXC_OUTPUT
    ERROR_VARIABLE DXC_ERROR)
if(NOT DXC_RESULT EQUAL 0)
    message(FATAL_ERROR
        "Embedded V1514 smoke shader failed DXC validation:\n${DXC_OUTPUT}\n${DXC_ERROR}")
endif()

message(STATUS "V1514 packed-basis smoke world-up contract verified")
