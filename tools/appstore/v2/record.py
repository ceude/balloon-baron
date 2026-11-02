"""record.py <simctl> <udid> <out.mov> <seconds>: records the simulator's screen for <seconds>, then stops the
recorder with SIGINT (what makes it finish the file) and waits for it. The recorder runs in its own session with
default signal handling (a shell script's background jobs would start with SIGINT ignored)."""
import os, signal, subprocess, sys, time
simctl, udid, out, secs = sys.argv[1], sys.argv[2], sys.argv[3], float(sys.argv[4])
p = subprocess.Popen([simctl, 'io', udid, 'recordVideo', '--codec=h264', '--force', out], stdin=subprocess.DEVNULL,
                     stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, start_new_session=True,
                     preexec_fn=lambda: (signal.signal(signal.SIGINT, signal.SIG_DFL), signal.pthread_sigmask(signal.SIG_UNBLOCK, [signal.SIGINT])))
# wait for "Recording started" so the length is the recording's
t0 = time.time()
line = ''
while time.time() - t0 < 20:
    line = p.stdout.readline()
    if 'started' in line or not line: break
time.sleep(secs)
for sig, wait in ((signal.SIGINT, 90), (signal.SIGINT, 30), (signal.SIGTERM, 20)):
    p.send_signal(sig)
    try:
        rest = p.communicate(timeout=wait)[0]
        print('recorder:', (line + rest).strip().replace('\n', ' | '), '| exit', p.returncode)
        sys.exit(0)
    except subprocess.TimeoutExpired:
        print('recorder: no exit after', sig.name)
p.kill()
print('recorder: killed')
