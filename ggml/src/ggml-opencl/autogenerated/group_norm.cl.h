R"(#pragma OPENCL EXTENSION cl_khr_fp16 : enable
)"
R"(
)"
R"(#ifdef cl_intel_subgroups
)"
R"(#pragma OPENCL EXTENSION cl_intel_subgroups : enable
)"
R"(#else
)"
R"(#pragma OPENCL EXTENSION cl_khr_subgroups : enable
)"
R"(#endif
)"
R"(
)"
R"(#ifdef cl_intel_required_subgroup_size
)"
R"(#pragma OPENCL EXTENSION cl_intel_required_subgroup_size : enable
)"
R"(#define INTEL_GPU 1
)"
R"(#define REQD_SUBGROUP_SIZE_16 __attribute__((intel_reqd_sub_group_size(16)))
)"
R"(#define REQD_SUBGROUP_SIZE_32 __attribute__((intel_reqd_sub_group_size(32)))
)"
R"(#elif defined(cl_qcom_reqd_sub_group_size)
)"
R"(#pragma OPENCL EXTENSION cl_qcom_reqd_sub_group_size : enable
)"
R"(#define ADRENO_GPU 1
)"
R"(#define REQD_SUBGROUP_SIZE_64  __attribute__((qcom_reqd_sub_group_size("half")))
)"
R"(#define REQD_SUBGROUP_SIZE_128 __attribute__((qcom_reqd_sub_group_size("full")))
)"
R"(#endif
)"
R"(
)"
R"(// Workgroup must be a subgroup
)"
R"(#ifdef INTEL_GPU
)"
R"(REQD_SUBGROUP_SIZE_32
)"
R"(#elif defined (ADRENO_GPU)
)"
R"(REQD_SUBGROUP_SIZE_64
)"
R"(#endif
)"
R"(kernel void kernel_group_norm(
)"
R"(        global float * src0,
)"
R"(        ulong offset0,
)"
R"(        global float * dst,
)"
R"(        ulong offsetd,
)"
R"(        int ne,
)"
R"(        int group_size,
)"
R"(        float eps
)"
R"() {
)"
R"(    src0 = (global float  *)((global char *)src0 + offset0);
)"
R"(    dst  = (global float *)((global char *)dst  + offsetd);
)"
R"(
)"
R"(    int start = get_group_id(0) * group_size;
)"
R"(    int end   = start + group_size;
)"
R"(
)"
R"(    start += get_local_id(0);
)"
R"(
)"
R"(    if (end >= ne) {
)"
R"(        end = ne;
)"
R"(    }
)"
R"(
)"
R"(    float tmp = 0.0f;
)"
R"(
)"
R"(    for (int j = start; j < end; j += get_local_size(0)) {
)"
R"(        tmp += src0[j];
)"
R"(    }
)"
R"(
)"
R"(    tmp = sub_group_reduce_add(tmp);
)"
R"(
)"
R"(    const float mean = tmp / group_size;
)"
R"(    tmp = 0.0f;
)"
R"(
)"
R"(    for (int j = start; j < end; j += get_local_size(0)) {
)"
R"(        float xi = src0[j] - mean;
)"
R"(        dst[j] = xi;
)"
R"(        tmp += xi * xi;
)"
R"(    }
)"
R"(
)"
R"(    tmp = sub_group_reduce_add(tmp);
)"
R"(
)"
R"(    const float variance = tmp / group_size;
)"
R"(    const float scale = 1.0f/sqrt(variance + eps);
)"
R"(    for (int j = start; j < end; j += get_local_size(0)) {
)"
R"(        dst[j] *= scale;
)"
R"(    }
)"
R"(}
)"
