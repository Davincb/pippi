cdef class Pulsar:
    cdef public double[:] freq
    cdef public double[:] amp
    cdef public double[:] wavetable
    cdef public double[:] window
    cdef public double[:] pulsewidth

    cdef double wt_phase
    cdef double win_phase
    cdef double freq_phase
    cdef double pw_phase
    cdef double amp_phase

    cdef public int channels
    cdef public int samplerate

    cdef object _play(self, int length)
