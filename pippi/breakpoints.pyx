#cython: language_level=3

from pippi.soundbuffer cimport SoundBuffer
from pippi cimport rand
from pippi cimport wavetables
from pippi cimport interpolation

import numpy as np
cimport numpy as np

cimport cython
from cpython.mem cimport PyMem_Malloc, PyMem_Realloc, PyMem_Free
from libc.stdlib cimport qsort

ctypedef int (*compare_t)(const void*, const void*) nogil

cdef int compare(const void* a, const void* b) nogil:
    cdef Point* p1 = <Point*>a
    cdef Point* p2 = <Point*>b

    if p1.x < p2.x:
        return -1
    elif p1.x > p2.x:
        return 1
    else:
        return 0

cdef class Breakpoint:
    def __cinit__(self, int numpoints=10, int wtsize=4096):
        self.numpoints = numpoints
        self.wtsize = wtsize

        cdef compare_t ct = compare

        self.points = <Point*>PyMem_Malloc(numpoints * sizeof(Point))

        # Endpoints at zero
        self.points[0].x = 0
        self.points[0].y = 0
        self.points[self.numpoints-1].x = 1
        self.points[self.numpoints-1].y = 0

        cdef int i = 0
        for i in range(self.numpoints-2):
            self.points[i+1].x = rand.rand(0, 1)
            self.points[i+1].y = rand.rand(-1, 1)

        qsort(<void*>self.points, self.numpoints, sizeof(Point), ct)

        for i in range(self.numpoints):
            print(self.points[i].x, self.points[i].y)
        print()

        self.out = np.zeros(self.wtsize, dtype='d')

    def render(self):
        cdef Point p1
        cdef Point p2
        cdef int x1, x2, x, width
        cdef int pi = 0

        cdef double b
        cdef double m 

        for pi in range(self.numpoints-1):
            p1 = self.points[pi]
            p2 = self.points[pi + 1]
            x1 = <int>(p1.x * self.wtsize)
            x2 = <int>(p2.x * self.wtsize)
            width = x2 - x1
            if width == 0:
                continue

            b = p1.y
            #m = (p2.y - p1.y) / (p2.x - p1.x)
            m = ((p2.y*2-1) - (p1.y*2-1)) / (p2.x - p1.x)
            #print('W', pi, 'b', b, 'm', m, 'width', width, 'x1', x1, 'x2', x2)
            print('W', x1 + width, b, m)
            for x in range(width):
                self.out[x1 + x] = m * x + b

    def drink(self, double width, double minval=-1, double maxval=1):
        cdef int i = 0
        for i in range(self.numpoints-2):
            self.points[i+1].y = max(minval, min(self.points[i+1].y + rand.rand(-width, width), maxval))
            self.points[i+1].x = max(0, min(self.points[i+1].x + rand.rand(-width, width), 1))

    def towavetable(self):
        self.render()
        return wavetables.Wavetable(self.out)

    def __dealloc__(self):
        PyMem_Free(self.points)

