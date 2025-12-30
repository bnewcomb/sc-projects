// Generative Chordal Movements in C Major
// Boot the server first if not already running
if(s.serverRunning.not, {
	"Booting server...".postln;
	s.boot;
	1.wait; // Wait for server to boot
}, {
	"Server already running.".postln;
});

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
	
	env = EnvGen.ar(Env.adsr(attack, 0.1, 0.7, release), gate, doneAction: 2);
	sig = Saw.ar(freq) * 0.5;
	sig = sig + Saw.ar(freq * 1.01) * 0.3;
	sig = sig + SinOsc.ar(freq * 2) * 0.2;
	sig = LPF.ar(sig, cutoff);
	sig = sig * env * amp;
	Out.ar(0, sig ! 2);
}).add;

// Helper: Check if server is ready
~checkServer = {
	if(s.serverRunning.not, {
		"ERROR: Server is not running! Please run: s.boot;".postln;
		^false;
	});
	^true;
};

// Helper: Safely get chord notes
~getChordNotes = { |chordName|
	var notes = ~cMajorChords[chordName];
	if(notes.isNil, {
		"WARNING: Chord '%' not found, using I chord instead.".format(chordName).postln;
		notes = ~cMajorChords[\I];
	});
	if(notes.isNil, {
		"ERROR: No chords defined!".postln;
		notes = [60, 64, 67]; // Fallback to C major
	});
	^notes;
};

// Play a chord progression
~playChordProgression = {
	arg chordNames, duration=2.0, transitionTime=0.5;
	
	// Validate inputs
	if(chordNames.isNil or: { chordNames.isEmpty }, {
		"ERROR: No chord names provided!".postln;
		^Routine({});
	});
	
	if(duration <= 0, {
		"ERROR: Duration must be positive!".postln;
		^Routine({});
	});
	
	if(transitionTime < 0, {
		"WARNING: Negative transition time, using 0.1".postln;
		transitionTime = 0.1;
	});
	
	if(transitionTime >= duration, {
		"WARNING: Transition time >= duration, adjusting...".postln;
		transitionTime = duration * 0.2;
	});
	
	^Routine({
		if(~checkServer.value.not, {
			"ERROR: Cannot play chords - server not running!".postln;
			^nil;
		});
		
		chordNames.do({
			arg chordName, index;
			var notes, synths;
			
			notes = ~getChordNotes.value(chordName);
			
			// Safely create synths
			synths = notes.collect({
				arg midiNote;
				var synth;
				if(midiNote.isNil, {
					"ERROR: Invalid MIDI note!".postln;
					nil;
				}, {
					synth = Synth(\chordPad, [
						\freq, midiNote.midicps,
						\amp, 0.12,
						\attack, 0.3,
						\release, transitionTime
					], s);
					if(synth.isNil, {
						"WARNING: Failed to create synth for note %".format(midiNote).postln;
					});
					synth;
				});
			}).select({ |s| s.notNil }); // Remove any nil synths
			
			if(synths.isEmpty, {
				"ERROR: No synths created for chord %!".format(chordName).postln;
			}, {
				// Release previous chord if not first
				if(index > 0 and: { ~currentSynths.notNil }, {
					~currentSynths.do({
						arg synth;
						if(synth.notNil, { synth.set(\gate, 0); });
					});
				});
				~currentSynths = synths;
				(duration - transitionTime).wait;
				
				// Fade out during transition
				if(index < (chordNames.size - 1), {
					synths.do({ |s| if(s.notNil, { s.set(\gate, 0); }); });
					transitionTime.wait;
				});
			});
		});
		
		// Release final chord
		if(~currentSynths.notNil, {
			~currentSynths.do({ |s| if(s.notNil, { s.set(\gate, 0); }); });
		});
	});
};

// Generate a chord progression
~generativeProgression = {
	arg length=8, seed=12345;
	var progression, current;
	
	// Validate inputs
	if(length < 1, {
		"WARNING: Length must be at least 1, using 4".postln;
		length = 4;
	});
	if(length > 50, {
		"WARNING: Length too large, limiting to 50".postln;
		length = 50;
	});
	
	thisThread.randSeed = seed;
	current = \I;
	progression = [current];
	
	(length - 1).do({
		var next;
		next = switch(current,
			\I, { [\IV, \V, \vi].choose },
			\ii, { [\V, \vi].choose },
			\iii, { [\vi, \IV].choose },
			\IV, { [\I, \V].choose },
			\V, { [\I, \vi].choose },
			\vi, { [\IV, \ii, \V].choose },
			\vii, { [\I].choose },
			{ [\I].choose }
		);
		if(next.notNil, {
			progression = progression.add(next);
			current = next;
		}, {
			"WARNING: Invalid chord transition, using I".postln;
			progression = progression.add(\I);
			current = \I;
		});
	});
	
	^progression;
};

// Main routine
~currentChordRoutine = nil;
~currentSynths = nil;

~makeChordRoutine = {
	if(~checkServer.value.not, {
		"ERROR: Cannot create routine - server not running!".postln;
		^nil;
	});
	
	^Routine({
		inf.do({
			var progression;
			progression = ~generativeProgression.value(
				length: 8,
				seed: Date.getDate.stamp.asInteger
			);
			if(progression.notNil and: { progression.notEmpty }, {
				progression.postln;
				~playChordProgression.value(progression, 2.5, 0.4).embedInStream;
			}, {
				"ERROR: Failed to generate progression!".postln;
			});
			1.0.wait;
		});
	});
};

// Control functions
~startChords = {
	if(~checkServer.value.not, {
		^false;
	});
	
	// Stop any existing routine
	if(~currentChordRoutine.notNil, {
		~currentChordRoutine.stop;
		~currentChordRoutine = nil;
	});
	
	// Create and start new routine
	~currentChordRoutine = ~makeChordRoutine.value;
	if(~currentChordRoutine.notNil, {
		~currentChordRoutine.play;
		"Chords started. Use ~stopChords to stop.".postln;
		^true;
	}, {
		"ERROR: Failed to start chords!".postln;
		^false;
	});
};

~stopChords = {
	var stopped = false;
	
	if(~currentChordRoutine.notNil, {
		~currentChordRoutine.stop;
		~currentChordRoutine = nil;
		stopped = true;
	});
	
	if(~currentSynths.notNil, {
		~currentSynths.do({
			arg synth;
			if(synth.notNil, { synth.set(\gate, 0); });
		});
		~currentSynths = nil;
		stopped = true;
	});
	
	if(stopped, {
		"Chords stopped.".postln;
	}, {
		"No chords were playing.".postln;
	});
};

~playExample = {
	if(~checkServer.value.not, {
		^false;
	});
	
	~playChordProgression.value([\I, \IV, \V, \vi, \IV, \V, \I], 2.0, 0.3).play;
	"Playing example progression.".postln;
	^true;
};

// Auto-start (only if server is ready)
~autoStart = true;

if(~autoStart, {
	Routine({
		// Wait for SynthDef to load
		0.2.wait;
		if(s.serverRunning, {
			~startChords.value;
		}, {
			"WARNING: Auto-start skipped - server not running. Run ~startChords.value; manually.".postln;
		});
	}).play;
});

"=== Generative Chordal Movements in C Major ===".postln;
"Available: ~startChords, ~stopChords, ~playExample".postln;

)
