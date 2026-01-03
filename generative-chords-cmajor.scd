// ============================================================================
// REGION 1: BOOT SERVER
// ============================================================================
// Evaluate this region FIRST (Ctrl+Enter on this section)
// ============================================================================

if(s.serverRunning, {
	"Server already running.".postln;
}, {
	"Booting server...".postln;
	s.boot;
	"Server booting... (wait a moment before evaluating next region)".postln;
});


// ============================================================================
// REGION 2: DEFINE SYNTHDEF
// ============================================================================
// Evaluate this region SECOND (Ctrl+Enter on this section)
// This sends the SynthDef to the server
// ============================================================================

(
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

"SynthDef 'chordPad' added to server.".postln;
)


// ============================================================================
// REGION 3: DEFINE CHORD DATA
// ============================================================================
// Evaluate this region THIRD (Ctrl+Enter on this section)
// ============================================================================

(
~cMajorChords = (
	I:   [60, 64, 67],  // C major
	ii:  [62, 65, 69],  // D minor
	iii: [64, 67, 71],  // E minor
	IV:  [65, 69, 72],  // F major
	V:   [67, 71, 74],  // G major
	vi:  [69, 72, 76],  // A minor
	vii: [71, 74, 77]   // B diminished
);

"Chord definitions loaded.".postln;
)


// ============================================================================
// REGION 4: SIMPLE TEST - PLAY ONE CHORD
// ============================================================================
// Evaluate this region to TEST if everything works
// You should hear a C major chord immediately
// ============================================================================

(
// Simple test - play one chord that auto-releases after 3 seconds
var notes, synths;
notes = ~cMajorChords[\I]; // C major chord
synths = notes.collect({
	arg midiNote;
	Synth(\chordPad, [
		\freq, midiNote.midicps,
		\amp, 0.2,
		\attack, 0.1,
		\release, 2.0,
		\gate, 1
	], s);
});
"Test: Created % synths. You should hear a C major chord for 3 seconds.".format(synths.size).postln;
// Auto-release after 3 seconds
Routine({
	3.wait;
	synths.do({ |s| if(s.notNil, { s.set(\gate, 0); }); });
	"Test chord released.".postln;
}).play;
)


// ============================================================================
// REGION 5: HELPER FUNCTIONS
// ============================================================================
// Evaluate this region to load helper functions
// ============================================================================

(
~checkServer = {
	if(s.serverRunning.not, {
		"ERROR: Server is not running! Please run: s.boot;".postln;
		^false;
	});
	^true;
};

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

"Helper functions loaded.".postln;
)


// ============================================================================
// REGION 6: CHORD PROGRESSION FUNCTION
// ============================================================================
// Evaluate this region to load the progression player
// ============================================================================

(
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
		transitionTime = 0.1;
	});
	
	if(transitionTime >= duration, {
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
			"Playing chord: % (notes: %)".format(chordName, notes).postln;
			
			// Create synths
			synths = notes.collect({
				arg midiNote;
				Synth(\chordPad, [
					\freq, midiNote.midicps,
					\amp, 0.12,
					\attack, 0.3,
					\release, transitionTime
				], s);
			});
			
			// Release previous chord if not first
			if(index > 0 and: { ~currentSynths.notNil }, {
				~currentSynths.do({ |s| if(s.notNil, { s.set(\gate, 0); }); });
			});
			
			~currentSynths = synths;
			(duration - transitionTime).wait;
			
			// Fade out during transition
			if(index < (chordNames.size - 1), {
				synths.do({ |s| if(s.notNil, { s.set(\gate, 0); }); });
				transitionTime.wait;
			});
		});
		
		// Release final chord
		if(~currentSynths.notNil, {
			~currentSynths.do({ |s| if(s.notNil, { s.set(\gate, 0); }); });
		});
	});
};

"Chord progression function loaded.".postln;
)


// ============================================================================
// REGION 7: GENERATIVE PROGRESSION FUNCTION
// ============================================================================
// Evaluate this region to load the generative algorithm
// ============================================================================

(
~generativeProgression = {
	arg length=8, seed=12345;
	var progression, current;
	
	if(length < 1, { length = 4; });
	if(length > 50, { length = 50; });
	
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
			progression = progression.add(\I);
			current = \I;
		});
	});
	
	^progression;
};

"Generative progression function loaded.".postln;
)


// ============================================================================
// REGION 8: MAIN ROUTINE AND CONTROL FUNCTIONS
// ============================================================================
// Evaluate this region to load control functions
// ============================================================================

(
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
			});
			1.0.wait;
		});
	});
};

~startChords = {
	if(~checkServer.value.not, { ^false; });
	
	if(~currentChordRoutine.notNil, {
		~currentChordRoutine.stop;
		~currentChordRoutine = nil;
	});
	
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
	if(~currentChordRoutine.notNil, {
		~currentChordRoutine.stop;
		~currentChordRoutine = nil;
	});
	if(~currentSynths.notNil, {
		~currentSynths.do({ |s| if(s.notNil, { s.set(\gate, 0); }); });
		~currentSynths = nil;
	});
	"Chords stopped.".postln;
};

~playExample = {
	if(~checkServer.value.not, { ^false; });
	~playChordProgression.value([\I, \IV, \V, \vi, \IV, \V, \I], 2.0, 0.3).play;
	"Playing example progression.".postln;
	^true;
};

// Quick test - play a short progression immediately
~testProgression = {
	if(~checkServer.value.not, { ^false; });
	"Testing progression: I IV V vi".postln;
	~playChordProgression.value([\I, \IV, \V, \vi], 1.5, 0.3).play;
	^true;
};

"Control functions loaded.".postln;
"".postln;
"=== READY ===".postln;
"".postln;
"IMPORTANT: After loading all regions, you must START the generative chords:".postln;
"".postln;
"  ~testProgression.value;  - Test with a short 4-chord progression".postln;
"  ~startChords.value;      - Start continuous generative chords".postln;
"  ~stopChords.value;       - Stop chords".postln;
"  ~playExample.value;      - Play example progression".postln;
"".postln;
)
