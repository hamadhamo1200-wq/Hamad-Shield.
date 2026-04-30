#include <substrate.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>
#include <sys/sysctl.h>

extern "C" int sysctl(int *, u_int, void *, size_t *, void *, size_t);

static int (*orig_sysctl)(int *name, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen);

int custom_sysctl(int *name, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    int ret = orig_sysctl(name, namelen, oldp, oldlenp, newp, newlen);
    if (namelen >= 3 && name[0] == CTL_KERN && name[1] == KERN_PROC && name[2] == KERN_PROC_PID) {
        struct kinfo_proc *info = (struct kinfo_proc *)oldp;
        if (info && (info->kp_proc.p_flag & 0x00000800)) {
            info->kp_proc.p_flag &= ~0x00000800;
        }
    }
    return ret;
}

static __attribute__((constructor)) void init() {
    MSHookFunction((void *)sysctl, (void *)custom_sysctl, (void **)&orig_sysctl);
}
