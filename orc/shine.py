import dsp
import tune

def play(params={}):
    length      = params.get('length', dsp.stf(dsp.rand(0.1, 1)))
    volume      = params.get('volume', 20.0)
    volume = volume / 100.0 # TODO: move into param filter
    octave      = params.get('octave', 2) + 1 # Add one to compensate for an old error for now
    note        = params.get('note', ['d'])
    note = note[0]
    quality     = params.get('quality', tune.major)
    glitch      = params.get('glitch', False)
    superglitch = params.get('superglitch', False)
    glitchpad   = params.get('glitch-padding', 0)
    glitchenv   = params.get('glitch-envelope', False)
    pulse       = params.get('pulse', False)
    env         = params.get('envelope', False)
    ratios      = params.get('ratios', tune.terry)
    pad         = params.get('padding', False)
    bend        = params.get('bend', False)
    bpm         = params.get('bpm', 75.0)
    width       = params.get('width', False)
    wform       = params.get('waveforms', ['sine', 'line', 'phasor'])
    instrument  = params.get('instrument', 'r')
    scale       = params.get('scale', [1,6,5,4,8])
    shuffle     = params.get('shuffle', False) # Reorganize input scale
    reps        = params.get('repeats', len(scale))

    if instrument == 'r':
        instrument = 'rhodes'
        tone = dsp.read('sounds/220rhodes.wav').data
    elif instrument == 'c':
        instrument = 'clarinet'
        tone = dsp.read('sounds/clarinet.wav').data
    elif instrument == 'v':
        instrument = 'vibes'
        tone = dsp.read('sounds/cz-vibes.wav').data
    elif instrument == 't':
        instrument = 'tape triangle'
        tone = dsp.read('sounds/tape220.wav').data
    elif instrument == 'g':
        instrument = 'guitar'
        tone = dsp.mix([dsp.read('sounds/guitar.wav').data, 
                        dsp.read('sounds/banjo.wav').data])

    out = ''

    # Translate the list of scale degrees into a list of frequencies
    freqs = tune.fromdegrees(scale, octave, note, quality, ratios)

    if shuffle is not False:
        freqs = dsp.randshuffle(freqs)

    for i in range(reps):
        #freq = tune.step(i, note, octave, scale, quality, ratios)
        freq = freqs[i % len(freqs)]

        if instrument == 'clarinet':
            diff = freq / 293.7
        else:
            diff = freq / 440.0

        clang = dsp.transpose(tone, diff)

        if env is not False:
            clang = dsp.env(clang, env)

        clang = dsp.fill(clang, length)

        if width is not False:
            width = int(length * float(width))

            clang = dsp.pad(dsp.cut(clang, 0, width), 0, length - width)

        if env is not False:
            clang = dsp.env(clang, env)

        if pad is not False:
            clang = dsp.pad(clang, 0, pad)

        out += clang

    if glitch == True:
        if superglitch is not False:
            mlen = dsp.mstf(superglitch)
        else:
            mlen = dsp.flen(out) / 8

        out = dsp.vsplit(out, dsp.mstf(1), mlen)
        out = [dsp.pan(o, dsp.rand()) for o in out]

        if glitchenv is not False:
            out = [dsp.env(o, glitchenv) for o in out]

        if glitchpad > 0:
            out = [dsp.pad(o, 0, dsp.mstf(dsp.rand(0, glitchpad))) for o in out]

        out = ''.join(dsp.randshuffle(out))

    if pulse == True:
        plen = dsp.mstf(dsp.rand(500, 1200))
        out = dsp.split(out, plen)
        mpul = len(out) / dsp.randint(4, 8)

        out = [dsp.env(o) * mpul for i, o in enumerate(out) if i % mpul == 0]
        opads = dsp.wavetable('sine', len(out), dsp.rand(plen * 0.25, plen))
        out = [dsp.pad(o, 0, int(opads[i])) for i, o in enumerate(out)]
        out = dsp.env(''.join(out))

    if bend == True:
        out = dsp.split(out, 441)
        freqs = dsp.wavetable('sine', len(out), 1.01, 0.99)
        out = [ dsp.transpose(out[i], freqs[i]) for i in range(len(out)) ]
        out = ''.join(out)

    return dsp.amp(out, volume)
