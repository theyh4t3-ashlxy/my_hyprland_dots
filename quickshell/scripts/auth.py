#!/usr/bin/env python3
import ctypes
import ctypes.util
import getpass
import os
import subprocess
import sys

def check_unix_chkpwd(username, password):
    # setuid binary lookup so non-root doesn't choke on /etc/shadow
    binaries = ["/usr/bin/unix_chkpwd", "/sbin/unix_chkpwd", "/usr/sbin/unix_chkpwd"]
    for chk in binaries:
        if os.path.exists(chk) and os.access(chk, os.X_OK):
            for args in [[chk, username, "nullok"], [chk, "nullok"]]:
                try:
                    p = subprocess.Popen(
                        args,
                        stdin=subprocess.PIPE,
                        stdout=subprocess.DEVNULL,
                        stderr=subprocess.DEVNULL
                    )
                    p.communicate(input=(password + "\x00").encode("utf-8"), timeout=3)
                    if p.returncode == 0:
                        return True
                except Exception:
                    pass
    return False

def check_pam(username, password):
    try:
        libpam = ctypes.CDLL(ctypes.util.find_library("pam") or "libpam.so.0")
        libc = ctypes.CDLL(ctypes.util.find_library("c") or "libc.so.6")
    except Exception:
        return False

    class PamMessage(ctypes.Structure):
        _fields_ = [("msg_style", ctypes.c_int), ("msg", ctypes.c_char_p)]

    class PamResponse(ctypes.Structure):
        _fields_ = [("resp", ctypes.c_void_p), ("resp_retcode", ctypes.c_int)]

    conv_func = ctypes.CFUNCTYPE(
        ctypes.c_int,
        ctypes.c_int,
        ctypes.POINTER(ctypes.POINTER(PamMessage)),
        ctypes.POINTER(ctypes.POINTER(PamResponse)),
        ctypes.c_void_p
    )

    class PamConv(ctypes.Structure):
        _fields_ = [("conv", conv_func), ("appdata_ptr", ctypes.c_void_p)]

    # fixing 64-bit pointer truncation before libc segfaults
    libc.strdup.restype = ctypes.c_void_p
    libc.strdup.argtypes = [ctypes.c_char_p]
    libc.calloc.restype = ctypes.c_void_p
    libc.calloc.argtypes = [ctypes.c_size_t, ctypes.c_size_t]

    libpam.pam_start.restype = ctypes.c_int
    libpam.pam_start.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.POINTER(PamConv), ctypes.POINTER(ctypes.c_void_p)]
    libpam.pam_authenticate.restype = ctypes.c_int
    libpam.pam_authenticate.argtypes = [ctypes.c_void_p, ctypes.c_int]
    libpam.pam_end.restype = ctypes.c_int
    libpam.pam_end.argtypes = [ctypes.c_void_p, ctypes.c_int]

    @conv_func
    def conv(n_msgs, msgs, resp, appdata):
        r_arr = (PamResponse * n_msgs)()
        for i in range(n_msgs):
            if msgs[i].contents.msg_style in (1, 2):
                r_arr[i].resp = libc.strdup(password.encode("utf-8"))
                r_arr[i].resp_retcode = 0
            else:
                r_arr[i].resp = None
                r_arr[i].resp_retcode = 0
        p = libc.calloc(n_msgs, ctypes.sizeof(PamResponse))
        ctypes.memmove(p, ctypes.byref(r_arr), ctypes.sizeof(PamResponse) * n_msgs)
        resp[0] = ctypes.cast(p, ctypes.POINTER(PamResponse))
        return 0

    c_struct = PamConv(conv=conv, appdata_ptr=None)
    pamh = ctypes.c_void_p()

    services = [b"quickshell", b"hyprlock", b"swaylock", b"system-local-login", b"login", b"system-auth", b"common-auth"]

    for service in services:
        ret = libpam.pam_start(service, username.encode("utf-8"), ctypes.byref(c_struct), ctypes.byref(pamh))
        if ret == 0:
            auth_ret = -1
            try:
                auth_ret = libpam.pam_authenticate(pamh, 0)
                if auth_ret == 0:
                    return True
            finally:
                libpam.pam_end(pamh, auth_ret if auth_ret != -1 else ret)

    return False

def main():
    username = os.environ.get("USER") or getpass.getuser()

    # readline doesn't deadlock waiting for eof
    if not sys.stdin.isatty():
        password = sys.stdin.readline().rstrip("\r\n\x00")
    elif len(sys.argv) > 1:
        password = sys.argv[1].rstrip("\r\n\x00")
    else:
        password = getpass.getpass("Password: ")

    if not password:
        sys.exit(1)

    # 1. try unix_chkpwd
    if check_unix_chkpwd(username, password):
        sys.exit(0)

    # 2. fallback to pam ctypes
    if check_pam(username, password):
        sys.exit(0)

    sys.exit(1)

if __name__ == "__main__":
    main()