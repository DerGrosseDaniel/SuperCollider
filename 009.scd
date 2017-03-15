(
//Quarks.gui;
//SimpleMIDIFile
//http://new-supercollider-mailing-lists-forums-use-these.2681727.n2.nabble.com/Read-a-SimpleMIDIFile-then-play-it-with-Pbind-td7608473.html
//https://github.com/supercollider-quarks/wslib
//Quarks.install("wslib");
//Quarks.install('\libs\wslib-master');
)

(
MIDIClient.init;
MIDIIn.connectAll;


//#######groupdefinitions
//Midihandling
~midi.free;
~midi = Group.new;
//oscillators
~oscs.free;
~oscs = Group.after(~midi);
//effects
~effects.free;
~effects = Group.after(~oscs);


~notes = Array.newClear(128);
~midiCC = Array.newClear(128);
//midi ControlChannels auf 0 setzen
(0..127).do({ |i|
	~midiCC[i] = Bus.control;
	~midiCC[i].set(0);
});
)


(
~osc1Out = Bus.alloc(\audio, s, 2);
~osc2Out = Bus.alloc(\audio, s, 2);
~reverbOut = Bus.alloc(\audio, s, 2);
~highpassOut = Bus.alloc(\audio, s, 2);
~lowpassOut = Bus.alloc(\audio, s, 2);
~lfo1Out = Bus.alloc(\audio, s,1);

MIDIdef.noteOn(\noteOn,{ arg vel, nn, chan, src;
	var sigSelect, pwm, amp;
	("noteon " + [vel, nn, chan]).postln;
	sigSelect = ~midiCC[81].get;
	pwm = ~midiCC[89].get;
	amp = ~midiCC[97].get;
	~notes[nn] = Synth.new(\osc1,[
		\freq, nn.midicps,
		\gate, 1,
		\sigSelect, sigSelect,
		\pwm, pwm,
		\amp, amp,
		\lfoIn, 1
	],~oscs);
	~notes[nn].map(
		\lfoIn, ~lfo1Out,
		\sigSelect, ~midiCC[81],
		\pwm, ~midiCC[89],
		\amp, ~midiCC[97],
	);

});



MIDIdef.noteOff(\noteOff,{ arg vel, nn, chan, src;
	("noteoff "+ [vel, nn, chan]).postln;
	~notes[nn].set(\gate, 0);
	//~notes[nn].free;
	~notes[nn] = nil;
});



MIDIdef.cc(\ccTest,{ arg ccNum, chan, srcID;
	("Channel " + chan + " set to " + (ccNum/127) + "  " + [ccNum, chan, srcID]).postln;
	~midiCC[chan].set(ccNum/127);
});






SynthDef(\osc1, {
	arg freq=440, gate = 1, sigSelect = 0, pwm = 0.5, amp = 0.5, lfoIn = 1;
	var sig, sigTri, sigSaw, sigSquare, sigNoise, env;
	env = EnvGen.kr(Env.adsr, gate, doneAction:2);
	sigTri = LFTri.ar(freq,0,amp) * linlin(sigSelect, 0 , 0.333 , 1 , 0);
	sigSaw = LFSaw.ar(freq,0,amp) * linlin((sigSelect-0.333).abs,0,0.333,1,0);
	sigSquare = LFPulse.ar(freq,0,pwm,amp) * linlin((sigSelect-0.666).abs,0,0.333,1,0);
	sigNoise = LFNoise0.ar(freq,amp) * linlin(sigSelect, 0.75 , 1 , 0 , 1);
	sig = (sigTri + sigSaw + sigSquare + sigNoise) * env * lfoIn;
	Out.ar(~osc1Out, sig!2);
}).add;
)

(
SynthDef(\lfo1, {
	arg freq=0.5, sigSelect = 0, pwm = 0.5, amp = 1, bypass = 0, freqFilter = 1;
	var sig, sigTri, sigSaw, sigSquare;
	freq = linexp(freq,0,1,0.1,200);
	sigTri = (LFTri.ar(freq,0,amp) + 1 / 2) * linlin(sigSelect, 0 , 0.333 , 1 , 0);
	sigSaw = (LFSaw.ar(freq,0,amp) + 1 / 2) * linlin((sigSelect-0.5).abs,0,0.5,1,0);
	sigSquare = LFPulse.ar(freq,0,pwm,amp) * linlin(sigSelect,0.5,1,0,1);
	sig = (sigTri + sigSaw + sigSquare);
	sig = LPF.ar(sig,linexp(freqFilter,0,1,1,22000));
	sig = ((1-bypass)*sig)+bypass;
	Out.ar(~lfo1Out, sig);
}).add;
)


(
SynthDef(\reverb, {
	arg in, out=0, mix = 0.33, room = 0.5, damp = 0.5;
	var inSig, sig;
	sig = In.ar(in,2);
	sig = FreeVerb.ar(sig,mix,room,damp);
	Out.ar(out, sig);
}).add;



SynthDef(\highpass, {
	arg in, out=0, freq = 50, rq = 1;
	var sig;
	sig = In.ar(in,2);
	//sig = RHPF.ar(sig,linexp(freq,0,1,0.2,22000),rq);
	sig = HPF.ar(sig,linexp(freq,0,1,0.2,22000));
	Out.ar(out, sig);
}).add;



SynthDef(\lowpass, {
	arg in, out=0, freq = 22000, rq = 1;
	var sig;
	sig = In.ar(in,2);
	//sig = RLPF.ar(sig,linexp(freq,0,1,0.2,22000),rq);
	sig = LPF.ar(sig,linexp(freq,0,1,0.2,22000));
	Out.ar(out, sig);
}).add;



SynthDef(\masterOut, {
	arg in;
	var inSig, sig;
	sig = In.ar(in,2);
	Out.ar(0, sig);
}).add;
)

//################## Patcharea ######################

(
var sigSelect, pwm, freq, bypass, freqFilter;
~lfo1.free;
freq = ~midiCC[82].get;
sigSelect = ~midiCC[90].get;
pwm = ~midiCC[98].get;
bypass = ~midiCC[99].get;
freqFilter = ~midiCC[91].get;
~lfo1 = Synth.new(\lfo1,[
	\freq, 50,
	\gate, 1,
	\sigSelect, sigSelect,
	\pwm, pwm,
	\amp, 1,
	\bypass, bypass,
	\freqFilter, freqFilter,
	],~oscs);
~lfo1.map(
	\freq, ~midiCC[82],
	\sigSelect, ~midiCC[90],
	\pwm, ~midiCC[98],
	\bypass, ~midiCC[99],
	\freqFilter, ~midiCC[91],
)


)

(
~effectHighpass.free;
~effectHighpass = Synth.new(\highpass, [
	\in, ~osc1Out,
	\out, ~highpassOut,
],~effects,\addToHead);
~effectHighpass.map(
	\freq, ~midiCC[1],
	\rq, ~midiCC[2],
);
)


(
~effectLowpass.free;
~effectLowpass = Synth.after(~effectHighpass,\lowpass, [
	\in, ~highpassOut,
	\out, ~lowpassOut,
]);
~effectLowpass.map(
	\freq, ~midiCC[3],
	\rq, ~midiCC[4],
);
)

(
~effectReverb.free;
~effectReverb = Synth.after(~effectLowpass,\reverb, [
	\in, ~lowpassOut,
	\out, ~reverbOut,
]);
~effectReverb.map(
	\mix, ~midiCC[6],
	\room, ~midiCC[7],
	\damp, ~midiCC[8],
);
)




(
~master.free;
~master = Synth.after(~effects,\masterOut, [
	\in, ~reverbOut,
]);
)

