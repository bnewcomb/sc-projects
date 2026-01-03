// ============================================================================
// GENERATIVE AMBIENT PATCH
// ============================================================================
// An endlessly evolving ambient soundscape with:
// - Layered drones with slow morphing textures
// - Parametric chaos and non-linear change
// - Sparse melodic seeds that drift unpredictably
// - Deep spatialization via reverb and shimmer
// - Minimal, quasi-perceptible rhythm
// - Environmental integration hooks
//
// Architecture:
// - Multiple SynthDefs for different texture layers
// - Chaos generators (Lorenz, logistic map) for non-repeating evolution
// - Stochastic event generators for sparse melodic events
// - Reverb/delay network for immersive space
// - Time-based entropy ensures unique output each run
// ============================================================================

// ============================================================================
// BOOT SERVER
// ============================================================================

if(s.serverRunning.not, {
	"Booting server...".postln;
	s.boot;
});


// ============================================================================
// SYNTHDEFS - DRONE LAYERS
// ============================================================================

// Base drone: slow-evolving sine waves with detuning and chaos
SynthDef(\droneBase, {
	arg freq=60, amp=0.15, gate=1,
	    chaosRate=0.1, chaosDepth=0.3,
	    detune=0.02, lfoRate=0.05, lfoDepth=0.1,
	    attack=8, release=12, out=0;  // Attack/release as parameters
	var sig, env, chaos, lfo, detuned;
	
	// Chaos generator for non-linear frequency modulation
	chaos = LFDNoise3.kr(chaosRate, chaosDepth);
	
	// Slow LFO for gentle morphing
	lfo = SinOsc.kr(lfoRate, 0, lfoDepth);
	
	// Detuned oscillators for rich texture
	detuned = [
		freq * (1 + detune + chaos + lfo),
		freq * (1 - detune + chaos + lfo),
		freq * (1 + (detune * 0.5) + chaos - lfo)
	];
	
	sig = SinOsc.ar(detuned).sum;
	
	// Envelope with configurable attack/release
	env = EnvGen.kr(Env.asr(attack, 1, release, curve: \sine), gate, doneAction: 2);
	sig = sig * env * amp;
	
	Out.ar(out, sig ! 2);
}).add;

// Harmonic drone: rich overtones with filter modulation
SynthDef(\droneHarmonic, {
	arg freq=120, amp=0.12, gate=1,
	    harmonicSpread=1.5, filterRate=0.03, filterDepth=0.4,
	    resonance=0.7, out=0;
	var sig, env, filterMod, harmonics;
	
	// Multiple harmonics with slight detuning
	harmonics = [1, 2, 3, 4, 5].collect({ |h|
		SinOsc.ar(freq * h * (1 + (h * 0.01 * harmonicSpread)))
	});
	sig = harmonics.sum;
	
	// Slow filter modulation
	filterMod = SinOsc.kr(filterRate, 0, filterDepth).range(0.3, 1.0);
	sig = RLPF.ar(sig, freq * 8 * filterMod, resonance);
	
	env = EnvGen.kr(Env.asr(10, 1, 15, curve: \sine), gate, doneAction: 2);
	sig = sig * env * amp;
	
	Out.ar(out, sig ! 2);
}).add;

// Noise-based texture: filtered noise with slow spectral evolution
SynthDef(\droneNoise, {
	arg amp=0.08, gate=1,
	    filterRate=0.02, filterMin=200, filterMax=2000,
	    resonance=0.3, noiseType=0, out=0;
	var sig, env, filterMod;
	
	// Choose noise type (0=pink, 1=brown, 2=white)
	sig = Select.ar(noiseType, [
		PinkNoise.ar,
		BrownNoise.ar,
		WhiteNoise.ar * 0.3
	]);
	
	// Slow filter sweep
	filterMod = LFSaw.kr(filterRate, 0, 0.5, 0.5);
	sig = RLPF.ar(sig, filterMod.range(filterMin, filterMax), resonance);
	
	env = EnvGen.kr(Env.asr(12, 1, 18, curve: \sine), gate, doneAction: 2);
	sig = sig * env * amp;
	
	Out.ar(out, sig ! 2);
}).add;

// Shimmer layer: high-frequency content with pitch-shifted reverb
SynthDef(\droneShimmer, {
	arg freq=800, amp=0.1, gate=1,
	    shimmerDepth=0.5, shimmerRate=0.07, out=0;
	var sig, env, shimmer;
	
	sig = SinOsc.ar(freq) + SinOsc.ar(freq * 1.5) * 0.5;
	
	// Shimmer effect: pitch-shifted feedback
	shimmer = DelayN.ar(sig, 0.1, 0.05);
	shimmer = PitchShift.ar(shimmer, 0.1, 1.12, 0, 0.01);
	sig = sig + (shimmer * shimmerDepth);
	
	env = EnvGen.kr(Env.asr(6, 1, 10, curve: \sine), gate, doneAction: 2);
	sig = sig * env * amp;
	
	Out.ar(out, sig ! 2);
}).add;

// Sparse melodic seed: occasional drifting pitches
SynthDef(\melodicSeed, {
	arg freq=440, amp=0.2, gate=1,
	    driftRate=0.15, driftDepth=0.1,
	    attack=2, release=8, out=0;
	var sig, env, drift;
	
	// Slow frequency drift
	drift = LFDNoise3.kr(driftRate, driftDepth);
	sig = SinOsc.ar(freq * (1 + drift));
	
	// Add subtle harmonics
	sig = sig + SinOsc.ar(freq * 2) * 0.3;
	sig = sig + SinOsc.ar(freq * 3) * 0.15;
	
	// Gentle envelope
	env = EnvGen.kr(Env([0, 1, 0.7, 0], [attack, 3, release], \sine), gate, doneAction: 2);
	sig = sig * env * amp;
	
	Out.ar(out, sig ! 2);
}).add;

// Ultra-slow pulse: quasi-perceptible rhythm
SynthDef(\slowPulse, {
	arg freq=0.1, amp=0.15, gate=1,
	    pulseFreq=80, pulseWidth=0.3, out=0;
	var sig, env, pulse, lfo;
	
	// Ultra-slow LFO (periods of 10+ seconds)
	lfo = SinOsc.kr(freq, 0, 0.5, 0.5);
	
	// Low-frequency pulse
	pulse = Pulse.ar(pulseFreq, pulseWidth);
	sig = pulse * lfo;
	
	// Gentle filtering
	sig = LPF.ar(sig, 200);
	
	env = EnvGen.kr(Env.asr(15, 1, 20, curve: \sine), gate, doneAction: 2);
	sig = sig * env * amp;
	
	Out.ar(out, sig ! 2);
}).add;

"SynthDefs loaded: droneBase, droneHarmonic, droneNoise, droneShimmer, melodicSeed, slowPulse".postln;


// ============================================================================
// SPATIALIZATION - REVERB & DELAY NETWORK
// ============================================================================

// Main reverb bus (create if not exists)
if(~reverbBus.isNil, {
	~reverbBus = Bus.audio(s, 2);
	"Reverb bus created.".postln;
}, {
	"Reverb bus already exists.".postln;
});

// Delay bus for chaining delay after reverb
if(~delayBus.isNil, {
	~delayBus = Bus.audio(s, 2);
	"Delay bus created.".postln;
}, {
	"Delay bus already exists.".postln;
});

// Reverb SynthDef
SynthDef(\reverb, {
	arg in=0, out=0, mix=0.6, room=0.9, damp=0.3;  // Increased mix for more reverb
	var sig, dry, wet;
	sig = In.ar(in, 2);
	// FreeVerb2 returns stereo, mix controls wet/dry
	wet = FreeVerb2.ar(sig[0], sig[1], 1.0, room, damp);
	dry = sig;
	sig = (dry * (1 - mix)) + (wet * mix);
	Out.ar(out, sig);
}).add;

// Delay network for spatial depth
SynthDef(\delayNetwork, {
	arg in=0, out=0, delayTime=0.3, feedback=0.3, mix=0.2;
	var sig, delayed;
	sig = In.ar(in, 2);
	delayed = AllpassC.ar(sig, 1, delayTime, 2);
	delayed = AllpassC.ar(delayed, 1, delayTime * 1.3, 2);
	sig = XFade2.ar(sig, delayed, mix * 2 - 1);
	Out.ar(out, sig);
}).add;

"Reverb and delay SynthDefs loaded.".postln;


// ============================================================================
// CHAOS GENERATORS & ENTROPY SOURCES
// ============================================================================

// Logistic map chaos generator
// Returns values that never repeat due to chaotic dynamics
~logisticMap = { |x, r|
	// r controls chaos: 3.57-4.0 is fully chaotic
	var rVal = r ? 3.8;
	^(rVal * x * (1 - x));
};

// Iterate logistic map for entropy
~getEntropy = { |seed, iterations=10|
	var val = seed;
	iterations.do({ val = ~logisticMap.value(val); });
	^val;
};

// Time-based seed generator (ensures unique output each run)
~getTimeSeed = {
	^Date.getDate.stamp.asInteger % 1000000 / 1000000.0;
};

// Frequency generator using chaos
~chaosFreq = { |baseFreq=60, chaosVal, octaveRange=2|
	var freq;
	chaosVal = chaosVal ? ~getEntropy.value(~getTimeSeed.value);
	freq = baseFreq * (2 ** (chaosVal * octaveRange - octaveRange/2));
	^freq;
};

"Chaos generators loaded.".postln;

// Test: Try to play a simple sound to verify audio works
fork {
	1.wait; // Wait for server
	if(s.serverRunning, {
		"Testing audio with simple tone...".postln;
		{ SinOsc.ar(440, 0, 0.1) * EnvGen.ar(Env([0,1,0], [0.1, 0.1]), doneAction: 2) ! 2 }.play;
		"Audio test complete.".postln;
	});
};

// ============================================================================
// GENERATIVE ENGINE
// ============================================================================

"Loading generative engine...".postln;

// Global state
~droneSynths = List.new;
~melodicSynths = List.new;
~pulseSynth = nil;
~reverbSynth = nil;
~delaySynth = nil;
~isRunning = false;
~entropyState = ~getTimeSeed.value;

// Initialize spatialization
~initSpatialization = {
	// Create reverb bus if it doesn't exist
	if(~reverbBus.isNil, {
		~reverbBus = Bus.audio(s, 2);
		"Reverb bus created.".postln;
	});
	
	// Create delay bus for chaining delay after reverb
	if(~delayBus.isNil, {
		~delayBus = Bus.audio(s, 2);
		"Delay bus created.".postln;
	});
	
	// Create reverb synth - outputs to delay bus
	if(~reverbSynth.isNil, {
		~reverbSynth = Synth.after(s.defaultGroup, \reverb, [
			\in, ~reverbBus.index,
			\out, ~delayBus.index,
			\mix, 0.6,  // Increased for more reverb
			\room, 0.9,
			\damp, 0.4
		]);
	});
	
	// Create delay synth - reads from delay bus, outputs to speakers
	if(~delaySynth.isNil, {
		~delaySynth = Synth.after(~reverbSynth, \delayNetwork, [
			\in, ~delayBus.index,
			\out, 0,
			\delayTime, 0.4,
			\feedback, 0.25,
			\mix, 0.15
		]);
	});
	"Spatialization initialized.".postln;
};

// Create a new drone layer with chaotic parameters
~spawnDrone = { |type=\droneBase, baseFreq=60|
	var synth, freq, params;
	
	// Use chaos to determine frequency
	~entropyState = ~logisticMap.value(~entropyState);
	freq = ~chaosFreq.value(baseFreq, ~entropyState);
	
	// Generate unique parameters using entropy
	params = [
		\freq, freq,
		\amp, 0.2 + (~entropyState * 0.15),  // Increased from 0.1
		\chaosRate, 0.05 + (~entropyState * 0.1),
		\chaosDepth, 0.2 + (~entropyState * 0.3),
		\detune, 0.01 + (~entropyState * 0.02),
		\lfoRate, 0.03 + (~entropyState * 0.05),
		\lfoDepth, 0.05 + (~entropyState * 0.1),
		\out, ~reverbBus.index
	];
	
	synth = Synth(type, params, s.defaultGroup);
	~droneSynths.add(synth);
	
	^synth;
};

// Spawn sparse melodic event
~spawnMelodicSeed = {
	var synth, freq, midiNote, scale;
	
	// Use entropy for pitch selection
	~entropyState = ~logisticMap.value(~entropyState);
	
	// Pentatonic scale for gentle, ambient-friendly intervals
	scale = [0, 2, 4, 7, 9, 12, 14, 16, 19, 21]; // C pentatonic + octaves
	midiNote = 48 + scale[(~entropyState * scale.size).asInteger.wrap(0, scale.size - 1)];
	freq = midiNote.midicps;
	
	// Random drift parameters
	synth = Synth(\melodicSeed, [
		\freq, freq,
		\amp, 0.15 + (~entropyState * 0.1),
		\driftRate, 0.1 + (~entropyState * 0.1),
		\driftDepth, 0.05 + (~entropyState * 0.1),
		\attack, 1 + (~entropyState * 3),
		\release, 5 + (~entropyState * 10),
		\out, ~reverbBus.index
	], s.defaultGroup);
	
	~melodicSynths.add(synth);
	
	^synth;
};

// Main generative routine
~generativeRoutine = Routine({
	var nextDroneTime, nextMelodicTime, nextPulseTime;
	var droneCount = 0;
	var maxDrones = 4;
	
	// Initialize spatialization
	~initSpatialization.value;
	
	// Initial drone layers
	"Spawning initial drone layers...".postln;
	3.do({
		~spawnDrone.value(\droneBase, 60 + (droneCount * 20));
		droneCount = droneCount + 1;
	});
	~spawnDrone.value(\droneHarmonic, 120);
	~spawnDrone.value(\droneNoise);
	~spawnDrone.value(\droneShimmer, 800);
	"Initial drones spawned. Total active: %".format(~droneSynths.size).postln;
	
	// Ultra-slow pulse
	~entropyState = ~logisticMap.value(~entropyState);
	~pulseSynth = Synth(\slowPulse, [
		\freq, 0.05 + (~entropyState * 0.1), // 10-20 second periods
		\amp, 0.15,  // Increased from 0.1
		\pulseFreq, 60 + (~entropyState * 40),
		\out, ~reverbBus.index
	], s.defaultGroup);
	
	// Initialize timing (stochastic intervals)
	~entropyState = ~logisticMap.value(~entropyState);
	nextDroneTime = 15 + (~entropyState * 30); // 15-45 seconds
	
	~entropyState = ~logisticMap.value(~entropyState);
	nextMelodicTime = 20 + (~entropyState * 40); // 20-60 seconds
	
	~entropyState = ~logisticMap.value(~entropyState);
	nextPulseTime = 30 + (~entropyState * 60); // 30-90 seconds
	
	"Generative ambient patch started. Evolving endlessly...".postln;
	
	// Main loop - runs forever
	inf.do({
		var waitTime, eventType;
		
		// Determine next event using entropy
		waitTime = min(nextDroneTime, nextMelodicTime, nextPulseTime);
		waitTime.wait;
		
		// Update timers
		nextDroneTime = nextDroneTime - waitTime;
		nextMelodicTime = nextMelodicTime - waitTime;
		nextPulseTime = nextPulseTime - waitTime;
		
		// Spawn drone layer
		if(nextDroneTime <= 0, {
			// Occasionally remove old drones to prevent buildup
			if(~droneSynths.size >= maxDrones, {
				var oldSynth = ~droneSynths.removeAt(0);
				oldSynth.set(\gate, 0);
			});
			
			// Choose drone type using entropy
			~entropyState = ~logisticMap.value(~entropyState);
			eventType = [\droneBase, \droneHarmonic, \droneNoise, \droneShimmer][
				(~entropyState * 4).asInteger
			];
			
			~spawnDrone.value(eventType, 60 + (~entropyState * 200));
			
			// Schedule next drone
			~entropyState = ~logisticMap.value(~entropyState);
			nextDroneTime = 20 + (~entropyState * 40);
		});
		
		// Spawn melodic seed
		if(nextMelodicTime <= 0, {
			~spawnMelodicSeed.value;
			
			// Schedule next melodic event (sparse - 30-90 seconds)
			~entropyState = ~logisticMap.value(~entropyState);
			nextMelodicTime = 30 + (~entropyState * 60);
		});
		
		// Update pulse parameters (ultra-slow morphing)
		if(nextPulseTime <= 0, {
			if(~pulseSynth.notNil, {
				~entropyState = ~logisticMap.value(~entropyState);
				~pulseSynth.set(
					\freq, 0.05 + (~entropyState * 0.1),
					\pulseFreq, 60 + (~entropyState * 40)
				);
			});
			
			// Schedule next pulse update
			~entropyState = ~logisticMap.value(~entropyState);
			nextPulseTime = 45 + (~entropyState * 90);
		});
		
		// Periodically clean up finished synths
		~droneSynths = ~droneSynths.select({ |s| s.isRunning });
		~melodicSynths = ~melodicSynths.select({ |s| s.isRunning });
	});
});

"Generative engine loaded.".postln;
"~generativeRoutine created: %".format(~generativeRoutine.notNil).postln;

// Force evaluation to continue
nil;


// ============================================================================
// CONTROL FUNCTIONS
// ============================================================================

~startAmbient = {
	if(s.serverRunning.not, {
		"ERROR: Server not running! Please boot server first.".postln;
		^false;
	});
	
	// Check if generative routine exists
	if(~generativeRoutine.isNil, {
		"ERROR: Generative routine not defined!".postln;
		"Please evaluate Region 5 (GENERATIVE ENGINE) first.".postln;
		^false;
	});
	
	if(~isRunning, {
		"Ambient patch already running. Use ~stopAmbient to stop first.".postln;
		^false;
	});
	
	// Reset entropy state for new run
	~entropyState = ~getTimeSeed.value;
	
	// Start generative routine
	~generativeRoutine.reset;
	~generativeRoutine.play;
	~isRunning = true;
	
	"=== GENERATIVE AMBIENT PATCH STARTED ===".postln;
	"Endlessly evolving soundscape...".postln;
	"".postln;
	"Initial drones spawning (may take a few seconds to fade in)...".postln;
	"Use ~stopAmbient to stop.".postln;
	"".postln;
	
	^true;
};

~stopAmbient = {
	if(~isRunning.not, {
		"Ambient patch not running.".postln;
		^false;
	});
	
	// Stop routine
	~generativeRoutine.stop;
	~isRunning = false;
	
	// Release all synths
	~droneSynths.do({ |s| if(s.notNil, { s.set(\gate, 0); }); });
	~melodicSynths.do({ |s| if(s.notNil, { s.set(\gate, 0); }); });
	if(~pulseSynth.notNil, { ~pulseSynth.set(\gate, 0); });
	
	// Release spatialization synths
	if(~reverbSynth.notNil, { ~reverbSynth.free; ~reverbSynth = nil; });
	if(~delaySynth.notNil, { ~delaySynth.free; ~delaySynth = nil; });
	
	~droneSynths.clear;
	~melodicSynths.clear;
	~pulseSynth = nil;
	
	"Ambient patch stopped.".postln;
	^true;
};

// Adjust reverb parameters in real-time
~setReverb = { |mix=0.5, room=0.9, damp=0.4|
	if(~reverbSynth.notNil, {
		~reverbSynth.set(\mix, mix, \room, room, \damp, damp);
		"Reverb updated: mix=%, room=%, damp=%".format(mix, room, damp).postln;
	}, {
		"Reverb not initialized. Start ambient patch first.".postln;
	});
};

// Adjust delay parameters
~setDelay = { |delayTime=0.4, feedback=0.25, mix=0.15|
	if(~delaySynth.notNil, {
		~delaySynth.set(\delayTime, delayTime, \feedback, feedback, \mix, mix);
		"Delay updated: time=%, feedback=%, mix=%".format(delayTime, feedback, mix).postln;
	}, {
		"Delay not initialized. Start ambient patch first.".postln;
	});
};

// Environmental integration: scale parameters by time of day
// hour: 0-23, affects overall energy and frequency range
~setTimeOfDay = { |hour=12|
	var energy, freqScale;
	
	// Map hour to energy (0-1): quieter at night, more active during day
	energy = sin((hour / 24) * pi);
	energy = energy.max(0.3); // Never completely silent
	
	// Scale frequencies: lower at night, higher during day
	freqScale = 0.7 + (energy * 0.6);
	
	// Adjust all active synths
	~droneSynths.do({ |s|
		if(s.notNil and: { s.isRunning }, {
			s.set(\amp, s.get(\amp) * energy);
		});
	});
	
	"Time of day set to %:00. Energy=%, FreqScale=%".format(hour, energy, freqScale).postln;
};

// Test function: play a simple tone directly to verify audio works
~testAudio = {
	if(s.serverRunning.not, {
		"ERROR: Server not running!".postln;
		^false;
	});
	
	"Testing audio output...".postln;
	{
		var sig = SinOsc.ar(440, 0, 0.3);
		sig = sig * EnvGen.ar(Env([0, 1, 1, 0], [0.1, 0.8, 0.1]), doneAction: 2);
		Out.ar(0, sig ! 2);
	}.play;
	"Test tone playing (440 Hz for 1 second). If you hear it, audio is working.".postln;
	^true;
};

// Test function: spawn a single drone directly to output (bypasses reverb)
~testDrone = {
	if(s.serverRunning.not, {
		"ERROR: Server not running!".postln;
		^false;
	});
	
	"Testing drone synth directly to output...".postln;
	Synth(\droneBase, [
		\freq, 60,
		\amp, 0.3,
		\out, 0  // Direct to output
	]);
	"Drone test playing. Should hear a low tone fading in over 8 seconds.".postln;
	^true;
};

// Diagnostic function: check routing and setup
~checkSetup = {
	"=== DIAGNOSTICS ===".postln;
	"".postln;
	"Server running: %".format(s.serverRunning).postln;
	"Reverb bus: %".format(if(~reverbBus.notNil, { "OK (index: %)".format(~reverbBus.index) }, { "MISSING" })).postln;
	"Delay bus: %".format(if(~delayBus.notNil, { "OK (index: %)".format(~delayBus.index) }, { "MISSING" })).postln;
	"Reverb synth: %".format(if(~reverbSynth.notNil and: { ~reverbSynth.isRunning }, { "RUNNING" }, { "NOT RUNNING" })).postln;
	"Delay synth: %".format(if(~delaySynth.notNil and: { ~delaySynth.isRunning }, { "RUNNING" }, { "NOT RUNNING" })).postln;
	"Active drones: %".format(if(~droneSynths.notNil, { ~droneSynths.size }, { 0 })).postln;
	"Patch running: %".format(~isRunning).postln;
	"".postln;
	^true;
};

"Control functions loaded.".postln;

// Force evaluation to continue  
nil;


// ============================================================================
// AUTO-START
// ============================================================================
// Automatically start the patch after a brief delay to ensure everything is loaded
// ============================================================================

// IMMEDIATE AUTO-START - starts right away with sound
"Starting patch immediately...".postln;

// Play immediate sound FIRST (before main patch)
fork {
	0.3.wait; // Brief wait for server
	if(s.serverRunning) {
		"Playing immediate drone sound...".postln;
		Synth(\droneBase, [
			\freq, 60,
			\amp, 0.4,  // Louder for immediate feedback
			\attack, 0.05,  // Very fast attack
			\release, 25,
			\out, 0  // Direct to output
		]);
		"Immediate sound started - you should hear a low drone NOW!".postln;
	};
};

// Start main patch
fork {
	// Wait for server
	var attempts = 0;
	while({ s.serverRunning.not and: { attempts < 20 } }, {
		0.1.wait;
		attempts = attempts + 1;
	});
	
	0.8.wait; // Wait for SynthDefs and functions to be ready
	
	"".postln;
	"=== AUTO-START DIAGNOSTICS ===".postln;
	"Server running: %".format(s.serverRunning).postln;
	"~startAmbient exists: %".format(~startAmbient.notNil).postln;
	"~generativeRoutine exists: %".format(~generativeRoutine.notNil).postln;
	"~isRunning: %".format(~isRunning).postln;
	"".postln;
	
	if(s.serverRunning and: { ~startAmbient.notNil and: { ~isRunning.not } }) {
		"=== GENERATIVE AMBIENT PATCH STARTING ===".postln;
		~startAmbient.value;
	} {
		"ERROR: Auto-start failed.".postln;
		"".postln;
		"MANUAL START REQUIRED:".postln;
		"  ~startAmbient.value;".postln;
		"".postln;
	};
};
