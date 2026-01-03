(
SynthDef(\sampleSynth, {
	arg out=0, gate=1, freq=220, amp=0.3, tempo=1.0;
	var env, warmPad, vocalSim, tapeSat, analogFilt, wobble, pan, sig, time, dust;

	// Long evolving envelope
	env = EnvGen.kr(Env([0, 0.7, 1, 0.8, 0], [8, 25, 30, 15] / tempo, [2, -2, 3, -4]), gate, doneAction: 2);
	time = SinOsc.kr(0.02 * tempo);

	// Warm analog-style pad
	warmPad = Mix.ar([
		Saw.ar(freq * [0.99, 1.01, 1.503]) * 0.4,
		Pulse.ar(freq * [0.5, 0.752], LFNoise1.kr(0.3).range(0.3, 0.7)) * 0.3
	]);

	// Simulated children's vocal formants
	vocalSim = Formant.ar(
		freq * [0.7, 0.9] + LFNoise1.kr(2).range(-5, 5),
		[800, 1200] + (time * 200),
		[100, 150],
		LFNoise1.kr(0.1).range(0.05, 0.15)
	);

	// Analog filter with slow modulation
	wobble = SinOsc.kr([0.07, 0.05] * tempo).range(0.3, 1.2);
	analogFilt = RLPF.ar(warmPad + vocalSim,
		(400 + (time * 600) + LFNoise1.kr(0.3).range(0, 300)) * wobble,
		0.4 + LFNoise1.kr(0.2).range(0, 0.3)
	);

	// Tape saturation simulation
	tapeSat = (analogFilt * 2.5).tanh * 0.6;

	// Nostalgic dust and crackle
	dust = Dust.ar([0.5, 0.7] * tempo) * Decay.ar(Impulse.ar(0), 0.05) * 0.02;

	// Slow stereo movement
	pan = SinOsc.kr(0.03 * tempo);
	sig = Balance2.ar(tapeSat[0] + dust[0], tapeSat[1] + dust[1], pan);

	// Final processing
	sig = HPF.ar(sig, 30);
	sig = Compander.ar(sig, sig, 0.3, 1, 0.3, 0.01, 0.3);
	sig = LeakDC.ar(sig * amp * env).clip(-0.95, 0.95);

	Out.ar(out, sig);
}).add;
)

x = Synth.new(\sampleSynth);