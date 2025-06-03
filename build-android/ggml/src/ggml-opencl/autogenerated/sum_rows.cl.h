R"(
)"
R"(kernel void kernel_sum_rows_f32(
)"
R"(    global float *  src0,
)"
R"(    ulong           offset0,
)"
R"(    global float *  dst,
)"
R"(    ulong           offsetd,
)"
R"(    int             ne00,
)"
R"(    int             ne01,
)"
R"(    int             ne02,
)"
R"(    int             ne03,
)"
R"(    ulong           nb01,
)"
R"(    ulong           nb02,
)"
R"(    ulong           nb03,
)"
R"(    ulong           nb1,
)"
R"(    ulong           nb2,
)"
R"(    ulong           nb3
)"
R"() {
)"
R"(    src0 = (global float *)((global char *)src0 + offset0);
)"
R"(    dst  = (global float *)((global char *)dst  + offsetd);
)"
R"(
)"
R"(    int i3 = get_global_id(2);
)"
R"(    int i2 = get_global_id(1);
)"
R"(    int i1 = get_global_id(0);
)"
R"(
)"
R"(    if (i3 >= ne03 || i2 >= ne02 || i1 >= ne01) {
)"
R"(        return;
)"
R"(    }
)"
R"(
)"
R"(    global float * src_row = (global float *) ((global char *) src0 + i1*nb01 + i2*nb02 + i3*nb03);
)"
R"(    global float * dst_row = (global float *) ((global char *) dst  + i1*nb1  + i2*nb2  + i3*nb3);
)"
R"(
)"
R"(    float row_sum = 0;
)"
R"(
)"
R"(    for (int i0 = 0; i0 < ne00; i0++) {
)"
R"(        row_sum += src_row[i0];
)"
R"(    }
)"
R"(
)"
R"(    dst_row[0] = row_sum;
)"
R"(}
)"
