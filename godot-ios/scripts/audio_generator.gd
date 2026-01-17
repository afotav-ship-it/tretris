extends Node
## Procedural audio generation for music and sound effects - Autoload singleton

const SAMPLE_RATE: float = 22050.0


func generate_landing_sound() -> AudioStreamWAV:
	var duration := 0.15
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	
	for i in range(samples):
		var t := float(i) / SAMPLE_RATE
		var decay := exp(-t * 25)
		
		var wave := sin(TAU * 80 * t) * 0.5 + \
					sin(TAU * 60 * t) * 0.3 + \
					sin(TAU * 40 * t) * 0.2
		var noise := (randf() - 0.5) * 0.3
		
		var value := int(((wave + noise) * decay) * 12000)
		value = clampi(value, -32000, 32000)
		
		# Stereo: duplicate for both channels
		data.append(value & 0xFF)
		data.append((value >> 8) & 0xFF)
		data.append(value & 0xFF)
		data.append((value >> 8) & 0xFF)
	
	return _create_wav(data)


func generate_blopper_sound() -> AudioStreamWAV:
	var duration := 0.2
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	
	for i in range(samples):
		var t := float(i) / SAMPLE_RATE
		var freq := 150 + 200 * sin(PI * t / duration)
		var decay := exp(-t * 10)
		
		var wave := sin(TAU * freq * t + sin(TAU * 20 * t) * 2)
		var value := int(wave * decay * 10000)
		value = clampi(value, -32000, 32000)
		
		data.append(value & 0xFF)
		data.append((value >> 8) & 0xFF)
		data.append(value & 0xFF)
		data.append((value >> 8) & 0xFF)
	
	return _create_wav(data)


func generate_explosion_sound(intensity: int = 1) -> AudioStreamWAV:
	var duration := 0.3 + intensity * 0.15
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	
	for i in range(samples):
		var t := float(i) / SAMPLE_RATE
		
		# Initial blast
		var blast_decay := exp(-t * (15 - intensity * 2))
		var blast_freq := 400 + intensity * 100
		var blast := sin(TAU * blast_freq * t * exp(-t * 3)) * blast_decay
		
		# Low rumble
		var rumble_freq := 40 + intensity * 10
		var rumble_decay := exp(-t * (3 - intensity * 0.3))
		var rumble := (sin(TAU * rumble_freq * t) * 0.5 + \
					   sin(TAU * rumble_freq * 0.5 * t) * 0.3) * rumble_decay
		
		# Crackling debris
		var noise_intensity := 0.3 + intensity * 0.15
		var noise_decay := exp(-t * (4 - intensity * 0.5))
		var noise := (randf() - 0.5) * noise_intensity * noise_decay
		
		# Shockwave
		var shockwave := 0.0
		if t < 0.1:
			shockwave = sin(TAU * 30 * t) * (1 - t * 10) * intensity * 0.3
		
		var wave := blast * 0.4 + rumble * 0.3 + noise + shockwave
		var amplitude := 8000 + intensity * 2000
		var value := int(wave * amplitude)
		value = clampi(value, -32000, 32000)
		
		data.append(value & 0xFF)
		data.append((value >> 8) & 0xFF)
		data.append(value & 0xFF)
		data.append((value >> 8) & 0xFF)
	
	return _create_wav(data)


func generate_folk_music(seed_value: int = -1, level: int = 1) -> AudioStreamWAV:
	if seed_value < 0:
		seed_value = randi()
	
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	
	# Minor pentatonic scale: A C D E G (two octaves)
	var scale := [220.0, 262.0, 294.0, 330.0, 392.0, 440.0, 523.0, 587.0, 659.0, 784.0]
	
	# Bass notes
	var bass_i := 110.0   # A (tonic)
	var bass_iv := 147.0  # D (subdominant)
	var bass_v := 165.0   # E (dominant)
	var bass_vi := 175.0  # F (submediant)
	
	# Generate melodic phrases
	var phrase_a := _generate_phrase(rng, scale, 1, "low")
	var phrase_b := _generate_phrase(rng, scale, 2, "medium")
	var phrase_c := _generate_phrase(rng, scale, 3, "high")
	
	# Choose song structure
	var structures := [
		["A", "A", "B", "A"],
		["A", "B", "A", "B"],
		["A", "A", "B", "C", "A"],
		["A", "B", "C", "B"],
		["A", "A", "A", "B"],
	]
	var structure: Array = structures[rng.randi() % structures.size()]
	
	var sections := { "A": phrase_a, "B": phrase_b, "C": phrase_c }
	
	# Build full melody
	var full_melody: Array[float] = []
	for section in structure:
		for note in sections[section]:
			full_melody.append(note)
	
	# Bass progression
	var bass_patterns := {
		"A": [bass_i, bass_i],
		"B": [bass_iv, bass_v],
		"C": [bass_vi, bass_v],
	}
	var full_bass: Array[float] = []
	for section in structure:
		for _i in range(2):
			for note in bass_patterns[section]:
				full_bass.append(note)
	
	# Tempo
	var bpm := 75 + rng.randf() * 15
	var note_duration := 60.0 / bpm
	var total_duration := full_melody.size() * note_duration
	
	var samples := int(SAMPLE_RATE * total_duration)
	var data := PackedByteArray()
	
	# Level-based features
	var has_rhythm := level >= 1
	var has_offbeat := level >= 2
	var has_harmony := level >= 3
	var has_counter := level >= 4
	var has_fills := level >= 5
	
	for i in range(samples):
		var t := float(i) / SAMPLE_RATE
		
		var note_idx := mini(int(t / note_duration), full_melody.size() - 1)
		var note_t := fmod(t, note_duration) / note_duration
		
		var freq := full_melody[note_idx]
		var bass_freq := full_bass[note_idx] if note_idx < full_bass.size() else bass_i
		
		# Envelope
		var attack := 0.08
		var sustain_end := 0.75
		var envelope: float
		if note_t < attack:
			envelope = note_t / attack
		elif note_t < sustain_end:
			envelope = 1.0 - (note_t - attack) * 0.08
		else:
			envelope = 0.92 * (1 - (note_t - sustain_end) / (1 - sustain_end))
		envelope = clampf(envelope, 0, 1)
		
		# Main melody
		var melody_wave := (sin(TAU * freq * t) * 0.40 + \
							sin(TAU * freq * 2 * t) * 0.12 + \
							sin(TAU * freq * 3 * t) * 0.04) * envelope
		
		# Harmony
		var harmony_wave := 0.0
		if has_harmony:
			var harm_freq := freq * 1.2
			harmony_wave = sin(TAU * harm_freq * t) * 0.08 * envelope
		
		# Counter-melody
		var counter_wave := 0.0
		if has_counter:
			var counter_t := fmod(t - 0.15, total_duration)
			if counter_t < 0:
				counter_t += total_duration
			var counter_idx := mini(int(counter_t / note_duration), full_melody.size() - 1)
			var counter_freq := full_melody[counter_idx] * 0.75
			counter_wave = sin(TAU * counter_freq * t) * 0.06 * envelope * 0.6
		
		# Bass
		var bass_wave := (sin(TAU * bass_freq * t) * 0.16 + \
						  sin(TAU * bass_freq * 2 * t) * 0.05)
		bass_wave += sin(TAU * bass_freq * 1.5 * t) * 0.04
		
		# Rhythm section
		var beat_num := fmod(t * bpm / 60, 4)
		var beat_phase := fmod(beat_num, 1)
		
		var kick := 0.0
		if has_rhythm:
			if beat_phase < 0.06 and (int(beat_num) == 0 or int(beat_num) == 2):
				kick = exp(-beat_phase * 60) * 0.12
		
		var hihat := 0.0
		if has_offbeat:
			if beat_phase < 0.03 and (int(beat_num) == 1 or int(beat_num) == 3):
				hihat = exp(-beat_phase * 120) * 0.06
		
		var fill := 0.0
		if has_fills:
			var bar_pos := note_idx % 16
			if bar_pos >= 14:
				var fill_phase := fmod(t * bpm / 60 * 2, 1)
				if fill_phase < 0.04:
					fill = exp(-fill_phase * 80) * 0.05
		
		var total := melody_wave + harmony_wave + counter_wave + bass_wave + kick + hihat + fill
		var value := int(total * 5500)
		value = clampi(value, -32000, 32000)
		
		data.append(value & 0xFF)
		data.append((value >> 8) & 0xFF)
		data.append(value & 0xFF)
		data.append((value >> 8) & 0xFF)
	
	return _create_wav(data, true)


func _generate_phrase(rng: RandomNumberGenerator, scale: Array, start_idx: int, energy: String) -> Array[float]:
	var patterns: Array
	
	match energy:
		"low":
			patterns = [[0, 1, 0, 0], [0, 2, 1, 0], [1, 0, 1, 0]]
		"medium":
			patterns = [[0, 2, 3, 2], [2, 1, 0, 2], [0, 1, 2, 1]]
		_:  # high
			patterns = [[2, 3, 4, 3], [3, 2, 4, 3], [0, 3, 2, 4]]
	
	var pattern: Array = patterns[rng.randi() % patterns.size()]
	var phrase: Array[float] = []
	
	for offset in pattern:
		var idx := clampi(start_idx + offset, 0, scale.size() - 1)
		phrase.append(scale[idx])
	
	return phrase


func _create_wav(data: PackedByteArray, looping: bool = false) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.stereo = true
	wav.mix_rate = int(SAMPLE_RATE)
	wav.data = data
	
	if looping:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_end = data.size() / 4  # 4 bytes per stereo sample
	
	return wav
