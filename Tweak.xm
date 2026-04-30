#import <substrate.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <sys/sysctl.h>

static int (*orig_sysctl)(int *name, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen);
int custom_sysctl(int *name, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    int ret = orig_sysctl(name, namelen, oldp, oldlenp, newp, newlen);
    if (name[0] == CTL_KERN && name[1] == KERN_PROC && name[2] == KERN_PROC_PID) {
        struct kinfo_proc *info = (struct kinfo_proc *)oldp;
        if (info && (info->kp_proc.p_flag & P_TRACED)) {
            info->kp_proc.p_flag ^= P_TRACED; 
        }
    }
    return ret;
}

%ctor {
    MSHookFunction((void *)sysctl, (void *)custom_sysctl, (void **)&orig_sysctl);
}
