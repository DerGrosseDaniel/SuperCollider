(
s.reboot;

MIDIClient.init;
MIDIIn.connectAll;

~notes = Array.newClear(128);
)


(

~noiseAmp = 0;

MIDIdef.cc(\ccTest,{ arg ccNum, chan, srcID;
	("Channel " + chan + " set to " + ccNum + "  " + [ccNum, chan, srcID]).postln;

	if(chan == 104){ //noise, row 4 knob 8
		~noiseAmp = ccNum.linlin(0,127,0,1);
		~notes.do{arg synth; synth.set(\noiseAmp, ~noiseAmp)};
	}

});

//MIDIdef.freeAll;

MIDIdef.noteOn(\noteOn,{ arg vel, nn, chan, src;
	("noteon " + [vel, nn, chan]).postln;
	~notes[nn] = 	Synth.new(
		\mainSynth,
		[
			\freq, nn.midicps,
			\amp, 0.5,
			\gate, 1,
			\noiseAmp, ~noiseAmp,
		]
	);
});


MIDIdef.noteOff(\noteOff,{ arg vel, nn, chan, src;
	("noteoff "+ [vel, nn, chan]).postln;
	~notes[nn].set(\gate, 0);
	~notes[nn] = nil;
});
)


(
SynthDef(\mainSynth,{
	arg freq = 440, amp = 0.3, gate = 0, noiseAmp = 0;
	var sig, env, noise;
	noise = LFNoise0.ar(freq)*noiseAmp;
	sig = LFSaw.ar(freq)!2*(1-noiseAmp);
	sig = sig + noise;
	env = EnvGen.kr(Env.adsr, gate, doneAction:2);
	sig = sig * env;
	Out.ar(0,sig);
}).add;
)





x = Synth.new(\mainSynth, [\gate, 1]);
x.set(\gate, 0);
x.free;



