#cython: language_level=3

import numbers
import numpy as np
from pippi.soundbuffer cimport SoundBuffer
from pippi cimport wavetables
from pippi cimport interpolation

cimport cython
cdef inline int DEFAULT_SAMPLERATE = 44100
cdef inline int DEFAULT_CHANNELS = 2
cdef inline double MIN_PULSEWIDTH = 0.0001

cdef class Osc:
    """ simple wavetable osc with linear interpolation
    """
    def __cinit__(
            self, 
            object wavetable=None, 
            object freq=440.0, 
            object amp=1.0,
            object pm=0.0,
            double phase=0, 

            int wtsize=4096,
            int channels=DEFAULT_CHANNELS,
            int samplerate=DEFAULT_SAMPLERATE,
        ):

        self.freq = wavetables.to_wavetable(freq, self.wtsize)
        self.amp = wavetables.to_window(amp, self.wtsize)
        self.pm = wavetables.to_wavetable(pm, self.wtsize)

        self.wt_phase = phase
        self.freq_phase = phase
        self.amp_phase = phase
        self.pm_phase = phase

        self.channels = channels
        self.samplerate = samplerate
        self.wtsize = wtsize

        self.wavetable = wavetables.to_wavetable(wavetable, self.wtsize)

    def play(self, length):
        framelength = <int>(length * self.samplerate)
        return self._play(framelength)

    cdef SoundBuffer _play(self, int length):
        cdef int i = 0
        cdef double sample, freq, amp, pm
        cdef double lastpm = 0
        cdef double ilength = 1.0 / length

        cdef int freq_boundry = max(len(self.freq)-1, 1)
        cdef int amp_boundry = max(len(self.amp)-1, 1)
        cdef int wt_boundry = max(len(self.wavetable)-1, 1)
        cdef int pm_boundry = max(len(self.pm)-1, 1)

        cdef double freq_phase_inc = ilength * freq_boundry
        cdef double amp_phase_inc = ilength * amp_boundry
        cdef double pm_phase_inc = ilength * pm_boundry

        cdef double wt_phase_inc = (1.0 / self.samplerate) * self.wtsize
        cdef double[:,:] out = np.zeros((length, self.channels), dtype='d')

        for i in range(length):
            freq = interpolation._linear_point(self.freq, self.freq_phase)
            amp = interpolation._linear_point(self.amp, self.amp_phase)
            pm = interpolation._linear_point(self.pm, self.pm_phase)
            sample = interpolation._linear_point(self.wavetable, self.wt_phase) * amp

            self.freq_phase += freq_phase_inc
            self.amp_phase += amp_phase_inc
            self.pm_phase += pm_phase_inc
            self.wt_phase += freq * wt_phase_inc
            self.wt_phase += (pm - lastpm) * wt_boundry * .5
            lastpm = pm

            if self.wt_phase < 0:
                self.wt_phase += wt_boundry
            elif self.wt_phase >= wt_boundry:
                self.wt_phase -= wt_boundry

            while self.amp_phase >= amp_boundry:
                self.amp_phase -= amp_boundry

            while self.freq_phase >= freq_boundry:
                self.freq_phase -= freq_boundry

            while self.pm_phase >= pm_boundry:
                self.pm_phase -= pm_boundry

            for channel in range(self.channels):
                out[i][channel] = sample

        return SoundBuffer(out, channels=self.channels, samplerate=self.samplerate)

