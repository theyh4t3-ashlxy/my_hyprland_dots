#!/usr/bin/env python3
"""
lockscreen authentication backend
verifies user credentials against unix_chkpwd and PAM
"""
import ctypes
import ctypes.util
import os
import subprocess
import sys
import getpass

def check_unix_chkpwd(username, password):
    for chk in ["/usr/bin/unix_chkpwd", "/sbin/unix_chkpwd", "/usr/sbin/unix_chkpwd"]:
        if os.path.exists(chk) and os.access(chk, os.X_OK):
            try:
                p = subprocess.Popen(
                    [chk, username, "nullok"],
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

    libc.strdup.restype = ctypes.c_void_p
    libc.strdup.argtypes = [ctypes.c_char_p]
    libc.calloc.restype = ctypes.c_void_p
    libc.calloc.argtypes = [ctypes.c_size_t, ctypes.c_size_t]

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

    for service in [b"login", b"system-auth", b"passwd", b"common-auth"]:
        ret = libpam.pam_start(service, username.encode("utf-8"), ctypes.byref(c_struct), ctypes.byref(pamh))
        if ret == 0:
            try:
                auth_ret = libpam.pam_authenticate(pamh, 0)
                if auth_ret == 0:
                    return True
            finally:
                libpam.pam_end(pamh, ret)

    return False

def main():
    username = os.environ.get("USER") or getpass.getuser()

    if len(sys.argv) > 1:
        password = sys.argv[1]
    else:
        password = sys.stdin.read().rstrip("\r\n\x00")

    if not password:
        sys.exit(1)

    # 1. try unix_chkpwd (rock solid setuid shadow verifier)
    if check_unix_chkpwd(username, password):
        sys.exit(0)

    # 2. fallback to pure pam conversation
    if check_pam(username, password):
        sys.exit(0)

    sys.exit(1)

if __name__ == "__main__":
    main()
