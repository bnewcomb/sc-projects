// Generative Chordal Movements in C Major
// Boot the server first: s.boot;

s.boot;

(
// Define chords in C major (MIDI note numbers, C4 = 60)
~cMajorChords = (
	I:   [60, 64, 67],  // C major
	ii:  [62, 65, 69],  // D minor
	iii: [64, 67, 71],  // E minor
	IV:  [65, 69, 72],  // F major
	V:   [67, 71, 74],  // G major
	vi:  [69, 72, 76],  // A minor
	vii: [71, 74, 77]   // B diminished
);

// SynthDef for a warm, pad-like chord sound
SynthDef(\chordPad, {
	arg freq=440, amp=0.15, gate=1, attack=0.5, release=2.0, cutoff=2000;
	var sig, env;

	env = EnvGen.ar(
		Env.adsr(attack, 0.1, 0.7, release),
		gate,
		doneAction: 2
	);

	// Rich harmonic content with slight detuning
	sig = Saw.ar(freq) * 0.5;
	sig = sig + Saw.ar(freq * 1.01) * 0.3;
	sig = sig + SinOsc.ar(freq * 2) * 0.2;

	// Smooth filtering
	sig = LPF.ar(sig, cutoff);
	sig = sig * env * amp;

	Out.ar(0, sig ! 2);
}).add;

// Generative chord progression function (returns a Routine)
~playChordProgression = {
	arg chordNames, duration=2.0, transitionTime=0.5;

	^Routine({
		"Chord progression routine started!".postln;
		chordNames.do({
			arg chordName, index;
			var notes, synths;

			"Processing chord % (index %)...".format(chordName, index).postln;
			notes = ~cMajorChords[chordName];
			if(notes.isNil, {
				"ERROR: Chord % not found!".format(chordName).postln;
				notes = ~cMajorChords[\I]; // fallback
			});
			
			"Creating synths for notes: %".format(notes).postln;
			synths = notes.collect({
				arg midiNote;
				var synth, freq;
				freq = midiNote.midicps;
				"  Creating synth: freq = % Hz".format(freq).postln;
				synth = Synth(\chordPad, [
					\freq, freq,
					\amp, 0.12,
					\attack, 0.3,
					\release, transitionTime
				], s);
				if(synth.isNil, {
					"  ERROR: Synth creation returned nil!".postln;
				}, {
					"  Synth created: %".format(synth).postln;
				});
				synth;
			});
			
			"Created % synths for chord %: %".format(synths.size, chordName, synths).postln;

			// Release previous chord if not first
			if(index > 0, {
				~currentSynths.do({ arg s; s.set(\gate, 0); });
			});

			~currentSynths = synths;

			// Hold chord for duration
			(duration - transitionTime).wait;

			// Fade out during transition
			if(index < (chordNames.size - 1), {
				synths.do({ arg s; s.set(\gate, 0); });
				transitionTime.wait;
			});
		});

		// Release final chord
		~currentSynths.do({ arg s; s.set(\gate, 0); });
	});
};

// Pattern-based generative progression
~generativeProgression = {
	arg length=8, seed=12345;
	var progression, current;

	thisThread.randSeed = seed;
	current = \I;
	progression = [current];

	(length - 1).do({
		var next;
		// Common chord progressions in C major with probabilities
		next = switch(current,
			\I, { [\IV, \V, \vi].choose },
			\ii, { [\V, \vi].choose },
			\iii, { [\vi, \IV].choose },
			\IV, { [\I, \V].choose },
			\V, { [\I, \vi].choose },
			\vi, { [\IV, \ii, \V].choose },
			\vii, { [\I].choose },
			{ [\I].choose } // default
		);
		progression = progression.add(next);
		current = next;
	});

	^progression;
};

// Variable to hold the current playing routine
~currentChordRoutine = nil;

// Function to create a new chord routine
~makeChordRoutine = {
	Routine({
		"Chord routine started!".postln;
		inf.do({
			var progression, seed;

			seed = Date.getDate.stamp.asInteger;
			progression = ~generativeProgression.value(length: 8, seed: seed);

			"Playing progression: ".post;
			progression.do({ arg c; c.post; " ".post; });
			"".postln;

			"About to embed chord progression routine...".postln;
			~playChordProgression.value(
				progression,
				duration: 2.5,
				transitionTime: 0.4
			).embedInStream;
			"Chord progression routine finished.".postln;

			// Pause between progressions
			1.0.wait;
		});
	});
};

// Start/stop functions
~startChords = {
	// Stop any existing routine first
	if(~currentChordRoutine.notNil, {
		~currentChordRoutine.stop;
	});
	
	// Verify server is running
	if(s.serverRunning.not, {
		"ERROR: Server not running! Please run: s.boot;".postln;
		^false;
	});
	
	// Create and play a new routine
	"Creating chord routine...".postln;
	~currentChordRoutine = ~makeChordRoutine.value;
	"Playing chord routine...".postln;
	~currentChordRoutine.play;
	"Generative chords started. Use ~stopChords to stop.".postln;
	^true;
};

~stopChords = {
	if(~currentChordRoutine.notNil, {
		~currentChordRoutine.stop;
		~currentChordRoutine = nil;
	});
	if(~currentSynths.notNil, {
		~currentSynths.do({ arg s; s.set(\gate, 0); });
	});
	"Chords stopped.".postln;
};

// Example: Play a specific progression
~playExample = {
	~playChordProgression.value(
		[\I, \IV, \V, \vi, \IV, \V, \I],
		duration: 2.0,
		transitionTime: 0.3
	).play;
};

// Test function to verify SynthDef is working
~testSynth = {
	"Testing SynthDef...".postln;
	if(s.serverRunning, {
		var testSynth;
		testSynth = Synth(\chordPad, [\freq, 440, \amp, 0.2], s);
		"Test synth created: %".format(testSynth).postln;
		"Check node tree - you should see a synth node.".postln;
		"Stop it with: s.freeAll;".postln;
		^testSynth;
	}, {
		"ERROR: Server not running!".postln;
		^nil;
	});
};

// Simple test - play one chord immediately
~testChord = {
	"Testing chord playback...".postln;
	if(s.serverRunning, {
		var notes, synths;
		notes = ~cMajorChords[\I];
		"Creating synths for notes: %".format(notes).postln;
		synths = notes.collect({
			arg midiNote;
			var synth, freq;
			freq = midiNote.midicps;
			"Creating synth: freq = %".format(freq).postln;
			synth = Synth(\chordPad, [
				\freq, freq,
				\amp, 0.15,
				\attack, 0.1,
				\release, 1.0
			], s);
			synth;
		});
		"Created % synths: %".format(synths.size, synths).postln;
		"Check node tree now!".postln;
		^synths;
	}, {
		"ERROR: Server not running!".postln;
		^nil;
	});
};

// Instructions
"".postln;
"=== Generative Chordal Movements in C Major ===".postln;
"".postln;
"Available functions:".postln;
"  ~startChords     - Start continuous generative progressions".postln;
"  ~stopChords      - Stop the generative routine".postln;
"  ~playExample     - Play a classic I-IV-V-vi progression".postln;
"".postln;
"Chord dictionary:".postln;
~cMajorChords.keysValuesDo({ arg key, val;
	"  %: %".format(key, val).postln;
});
"".postln;
"Boot the server first with: s.boot;".postln;
"".postln;

// Auto-start option (set to true to automatically start playing on load)
~autoStart = true;

if(~autoStart, {
	"Auto-starting generative chords...".postln;
	// Wait for SynthDef to be loaded before starting
	Routine({
		// Wait a moment for SynthDef to be sent to server
		0.1.wait;
		// Verify server is running
		if(s.serverRunning.not, {
			"ERROR: Server not running! Please run: s.boot;".postln;
		}, {
			"Starting chords...".postln;
			~startChords.value;
		});
	}).play;
}, {
	"".postln;
	"To start playing, run: ~startChords.value;".postln;
	"Or try: ~playExample.value;".postln;
	"".postln;
});

)

