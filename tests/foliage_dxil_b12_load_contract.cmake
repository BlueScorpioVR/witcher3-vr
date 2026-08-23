if(NOT DEFINED DXC_EXECUTABLE OR
   NOT DEFINED DISTANT_SHADER OR
   NOT DEFINED FROND_SHADER)
    message(FATAL_ERROR "foliage DXIL contract inputs are missing")
endif()

function(count_fragment text fragment output)
    string(REPLACE "${fragment}" "" without "${text}")
    string(LENGTH "${text}" before_length)
    string(LENGTH "${without}" after_length)
    string(LENGTH "${fragment}" fragment_length)
    math(EXPR count "(${before_length} - ${after_length}) / ${fragment_length}")
    set(${output} ${count} PARENT_SCOPE)
endfunction()

function(validate_shader path current_handle base_handle current_axis_count row9_count)
    execute_process(
        COMMAND "${DXC_EXECUTABLE}" -dumpbin "${path}"
        RESULT_VARIABLE result
        OUTPUT_VARIABLE dump
        ERROR_VARIABLE errors
    )
    if(NOT result EQUAL 0)
        message(FATAL_ERROR "DXIL validation failed for ${path}: ${errors}")
    endif()
    if(NOT dump MATCHES "Vertex Shader" OR
       NOT dump MATCHES "SV_Position" OR
       NOT dump MATCHES "cb0" OR
       NOT dump MATCHES "cb12")
        message(FATAL_ERROR "DXIL signature/resource contract missing: ${path}")
    endif()

    set(current_rows 12 13 14)
    foreach(row IN LISTS current_rows)
        count_fragment(
            "${dump}" "%dx.types.Handle %${current_handle}, i32 ${row})"
            current_count)
        if(NOT current_count EQUAL current_axis_count)
            message(FATAL_ERROR
                "unexpected current b0 row ${row} load count in ${path}: ${current_count}")
        endif()
    endforeach()
    count_fragment(
        "${dump}" "%dx.types.Handle %${current_handle}, i32 17)"
        current_direction_count)
    if(NOT current_direction_count EQUAL 0)
        message(FATAL_ERROR
            "current b0 row 17 remains in patched shader ${path}")
    endif()

    set(base_rows 4 5 6)
    foreach(row IN LISTS base_rows)
        count_fragment(
            "${dump}" "%dx.types.Handle %${base_handle}, i32 ${row})"
            base_count)
        if(NOT base_count EQUAL 2)
            message(FATAL_ERROR
                "expected two b12 row ${row} loads in ${path}, got ${base_count}")
        endif()
    endforeach()
    count_fragment(
        "${dump}" "%dx.types.Handle %${base_handle}, i32 9)"
        actual_row9_count)
    if(NOT actual_row9_count EQUAL row9_count)
        message(FATAL_ERROR
            "unexpected b12 row 9 load count in ${path}: ${actual_row9_count}")
    endif()
endfunction()

validate_shader("${DISTANT_SHADER}" 6 1 0 1)
validate_shader("${FROND_SHADER}" 8 3 1 2)
