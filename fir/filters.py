#!/usr/bin/env python3
import numpy as np
import scipy
from scipy import signal
import matplotlib.pyplot as plt

def round_int(h, nb):
    mult = 2**(int(nb))
    h *= mult
    h = np.round(h)
    c(h.astype(int))
    print(np.max(h))
    print(np.sum(h))
    print(h)
    return(h, h/np.sum(h))

def verilog(h, offset = 0):
    for i in range(int(len(h)/2)):
        print("coefrom[{}] = {};".format(i+offset, int(h[i])))

def c(h):
    print("{")
    for i in range(int(len(h)/2)):
        print("{}, ".format(int(h[i])),)
    print("}")

print("\n\n\n1st filter, decimate by 2 pass 0 - 3 MHz at 100 MSPS")
h1 = np.array([1604,  0,  -12992,  0,  76924, 131072, 76924, 0, -12992, 0, 1604], dtype=float)
print(np.sum(h1))
h1 /= 262144.0
(w1,H1) = signal.freqz(h1)

print("\n2nd filter, decimate by 2 pass 0 - 3 MHz at 50 MSPS")
h2 = signal.remez(11, [0., .06, .44, .5], [1,0], [1,1])
h2i, h2 = round_int(h2, 18)
print(h2)
c1 = 1834
c2 = -13638
c3 = 65536 - (c1 + c2)
h2 = np.array([c1,  0,  c2,  0,  c3, 131072, c3, 0, c2, 0, c1], dtype=float)
print(h2)
print(np.sum(h2))
h2 /= 262144
(w2,H2) = signal.freqz(h2)

print("\n3rd filter, decimate by 2 pass 0 - 3 MHz at 25 MSPS")
h3 = signal.remez(23, [0., .12, .38, .5], [1,0], [1,1])
h3i, h3 = round_int(h3, 25)
h3 = np.array([-79,  0,  603,  0,  -2529, 0, 7807, 0, -21298, 0, 81032, 131072, 81032, 0, -21298, 0, 7807, 0, -2529, 0, 603, 0, -79], dtype=float)
print(np.sum(h3))
h3 /= 262144.0
(w3,H3) = signal.freqz(h3)

print("\n4th filter, decimate by 2 pass 0 - 5 MHz at 6.25 MSPS")
h4 = signal.remez(59, [0.0, 0.2, 0.3, 0.5], [1,0], [1,1])
h4i, h4 = round_int(h4, 19)
#print np.max(h4i)
#h4 = np.round(h4*262144)
#print h4
#h4 /= np.sum(h4)
(w4,H4) = signal.freqz(h4)

fig = plt.figure()
ax = fig.add_subplot(111)
ax.plot(100e6*w1/(2.0*np.pi), 20*np.log10(np.abs(H1)))
ax.plot(50e6*w2/(2.0*np.pi), 20*np.log10(np.abs(H2)))
ax.plot(25e6*w3/(2.0*np.pi), 20*np.log10(np.abs(H3)))
ax.plot(12.5e6*w4/(2.0*np.pi), 20*np.log10(np.abs(H4)))
ax.legend(['1st', '2nd', '3rd', '4th'])
ax.axis([0,50e6,-120,3])
ax.grid('on')
ax.set_ylabel('Magnitude (dB)')
ax.set_xlabel('Frequency (MHz)')
ax.set_title('Decimation Filter Frequency Response')
fig.savefig('freqresp.pdf')
plt.show()
