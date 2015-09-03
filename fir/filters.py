#!/usr/bin/env python
import numpy as np
import scipy
from scipy import signal
import matplotlib.pyplot as plt

def round_int(h, nb):
    mult = 2**nb
    h /= np.sum(h)
    h *= mult
    h = np.round(h)
    #print repr((h).astype(int))
    c(h.astype(int))
    print np.max(h)
    print np.sum(h)
    return h, h/np.sum(h)

def verilog(h, offset = 0):
    for i in range(len(h)/2):
        print "coefrom[{}] = {};".format(i+offset, int(h[i]))

def c(h):
    print "{"
    for i in range(len(h)/2):
        print "{}, ".format(int(h[i])),
    print "}"

print "1st filter, decimate by 4 pass 0 - 5 MHz at 100 MSPS"
h1 = signal.remez(32, [0., .05, .20, .5], [1,0], [1,1])
h1i, h1 = round_int(h1, 19)
(w1,H1) = signal.freqz(h1)
verilog(h1i)

print "1st filter, decimate by 4 pass 0 - 2.5 MHz at 100 MSPS"
h1_1 = signal.remez(32, [0., .025, .225, .5], [1,0], [1,1])
h1i_1, h1_1 = round_int(h1_1, 19)
(w1_1,H1_1) = signal.freqz(h1_1)
verilog(h1i_1, 16)

"""
print "1st filter, decimate by 8 pass 0 - 2.5 MHz at 100 MSPS"
h1 = signal.remez(64, [0., .025, .10, .5], [1,0], [1,1])
(w1,H1) = signal.freqz(round_int(h1, 20))
verilog(h1)

print "1st filter, decimate by 8 pass 0 - 1.25 MHz at 100 MSPS"
h1_1 = signal.remez(64, [0., .0125, .1125, .5], [1,0], [1,1])
(w1_1,H1_1) = signal.freqz(round_int(h1_1, 20))
verilog(h1_1/8)#, 32)
"""

print "2nd filter, decimate by 2 pass 0 - 2.5 MHz at 12.5 MSPS"
h2 = signal.remez(64, [0., .2, .3, .5], [1,0], [1,1])
h2i, h2 = round_int(h2, 18)
(w2,H2) = signal.freqz(h2)

print "2nd filter, decimate by 4 pass 0 - 1.25 MHz at 12.5 MSPS"
h3 = signal.remez(128, [0., .2/2, .3/2, .5], [1,0], [1,1])
h3i, h3 = round_int(h3, 19)
(w3,H3) = signal.freqz(h3)

print "2nd filter, decimate by 8 pass 0 - 625 kHz at 12.5 MSPS"
h4 = signal.remez(256, [0., .2/4, .3/4, .5], [1,0], [1,1])
h4i, h4 = round_int(h4, 20)
(w4,H4) = signal.freqz(h4)

print "2nd filter, decimate by 16 pass 0 - 312.5 kHz at 12.5 MSPS"
h5 = signal.remez(512, [0., .2/8, .3/8, .5], [1,0], [1,1])
h5i, h5 = round_int(h5, 21)
(w5,H5) = signal.freqz(h5)

fig = plt.figure()
ax = fig.add_subplot(111)
ax.plot(w1/(2.0*np.pi), 20*np.log10(np.abs(H1)))
ax.plot(w1_1/(2.0*np.pi), 20*np.log10(np.abs(H1_1)))
ax.plot(w2/(2.0*np.pi), 20*np.log10(np.abs(H2)))
ax.plot(w3/(2.0*np.pi), 20*np.log10(np.abs(H3)))
ax.plot(w4/(2.0*np.pi), 20*np.log10(np.abs(H4)))
ax.plot(w5/(2.0*np.pi), 20*np.log10(np.abs(H5)))
ax.legend(['1st_5M', '1st_2.5M', '2nd_2', '2nd_4', '2nd_8', '2nd_16'])
ax.axis([0,0.5,-100,3])
ax.grid('on')
ax.set_ylabel('Magnitude (dB)')
ax.set_xlabel('Frequency normalized to FS')
ax.set_title('Decimation Filter Frequency Response')
fig.savefig('freqresp.pdf')
ax.axis([0,0.25,-0.01,0.01])
fig.savefig('freqresp_zoom.pdf')

bram = np.zeros(512, dtype=int)
bram[256:512] = h5i[:256]
bram[128:256] = h4i[:128]
bram[64:128] = h3i[:64]
bram[32:64] = h2i[:32]
bram[0:32] = np.arange(32) * 256 + 100*256
for i in range(len(bram)):
    print "coefrom[{}] = {};".format(i, int(bram[i]))
