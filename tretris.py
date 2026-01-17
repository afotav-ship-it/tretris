from typing import Optional

import pygame
import random
import sys
import array
import math

# Initialize pygame
pygame.init()
pygame.mixer.init(frequency=22050, size=-16, channels=2, buffer=512)

# Game constants
CELL_SIZE = 30
GRID_WIDTH = 16
GRID_HEIGHT = 16
SIDEBAR_WIDTH = 150
SCREEN_WIDTH = GRID_WIDTH * CELL_SIZE + SIDEBAR_WIDTH
SCREEN_HEIGHT = GRID_HEIGHT * CELL_SIZE

# Colors
BLACK = (0, 0, 0)
WHITE = (255, 255, 255)
GRAY = (128, 128, 128)
DARK_GRAY = (40, 40, 40)

# Random vibrant colors for blocks
BLOCK_COLORS = [
    (255, 0, 0),      # Red
    (0, 255, 0),      # Green
    (0, 0, 255),      # Blue
    (255, 255, 0),    # Yellow
    (255, 0, 255),    # Magenta
    (0, 255, 255),    # Cyan
    (255, 128, 0),    # Orange
    (128, 0, 255),    # Purple
    (255, 128, 128),  # Pink
    (128, 255, 128),  # Light Green
]

# Directions
UP = 0
DOWN = 1
LEFT = 2
RIGHT = 3

DIRECTION_NAMES = {UP: "UP", DOWN: "DOWN", LEFT: "LEFT", RIGHT: "RIGHT"}
DIRECTION_ARROWS = {UP: "^", DOWN: "v", LEFT: "<", RIGHT: ">"}

# Sound generation
def generate_landing_sound():
    """Generate a mushy/thud sound for block landing"""
    sample_rate = 22050
    duration = 0.15  # seconds
    samples = int(sample_rate * duration)
    
    # Create a low frequency thud with quick decay
    sound_data = array.array('h')  # signed short
    for i in range(samples):
        t = i / sample_rate
        # Low frequency base with noise for "mushy" effect
        decay = math.exp(-t * 25)  # Quick decay
        # Mix of low frequencies for thud
        wave = (math.sin(2 * math.pi * 80 * t) * 0.5 +
                math.sin(2 * math.pi * 60 * t) * 0.3 +
                math.sin(2 * math.pi * 40 * t) * 0.2)
        # Add some noise for texture
        noise = (random.random() - 0.5) * 0.3
        value = int(((wave + noise) * decay) * 12000)
        sound_data.append(value)  # Left channel
        sound_data.append(value)  # Right channel
    
    return pygame.mixer.Sound(buffer=sound_data)

def generate_collapse_sound():
    """Generate a rumbling collapse sound for line clearing"""
    sample_rate = 22050
    duration = 0.3  # seconds
    samples = int(sample_rate * duration)
    
    sound_data = array.array('h')
    for i in range(samples):
        t = i / sample_rate
        # Descending frequency for falling/collapse effect
        freq = 200 - (t * 400)  # Start high, go low
        freq = max(30, freq)  # Don't go below 30Hz
        decay = math.exp(-t * 5)
        
        # Rumbling effect with harmonics
        wave = (math.sin(2 * math.pi * freq * t) * 0.4 +
                math.sin(2 * math.pi * freq * 0.5 * t) * 0.3 +
                math.sin(2 * math.pi * freq * 0.25 * t) * 0.2)
        # Add crackling noise
        noise = (random.random() - 0.5) * 0.4 * decay
        value = int(((wave + noise) * decay) * 10000)
        sound_data.append(value)
        sound_data.append(value)
    
    return pygame.mixer.Sound(buffer=sound_data)

def generate_explosion_sound(intensity=1):
    """Generate an explosion sound proportional to intensity (1-5)"""
    sample_rate = 22050
    # Longer duration for bigger explosions
    duration = 0.3 + (intensity * 0.15)  # 0.45s to 1.05s
    samples = int(sample_rate * duration)
    
    sound_data = array.array('h')
    for i in range(samples):
        t = i / sample_rate
        
        # Initial blast - higher frequency burst that quickly drops
        blast_decay = math.exp(-t * (15 - intensity * 2))  # Slower decay for bigger explosions
        blast_freq = 400 + intensity * 100  # Higher initial freq for bigger explosions
        blast = math.sin(2 * math.pi * blast_freq * t * math.exp(-t * 3)) * blast_decay
        
        # Low rumble - sustained bass
        rumble_freq = 40 + intensity * 10
        rumble_decay = math.exp(-t * (3 - intensity * 0.3))
        rumble = (math.sin(2 * math.pi * rumble_freq * t) * 0.5 +
                  math.sin(2 * math.pi * rumble_freq * 0.5 * t) * 0.3) * rumble_decay
        
        # Crackling debris noise - more for bigger explosions
        noise_intensity = 0.3 + intensity * 0.15
        noise_decay = math.exp(-t * (4 - intensity * 0.5))
        noise = (random.random() - 0.5) * noise_intensity * noise_decay
        
        # Shockwave effect - a quick low frequency pulse
        if t < 0.1:
            shockwave = math.sin(2 * math.pi * 30 * t) * (1 - t * 10) * intensity * 0.3
        else:
            shockwave = 0
        
        # Mix all components
        wave = blast * 0.4 + rumble * 0.3 + noise + shockwave
        
        # Scale amplitude with intensity
        amplitude = 8000 + intensity * 2000
        value = int(wave * amplitude)
        value = max(-32000, min(32000, value))  # Clamp to prevent overflow
        sound_data.append(value)
        sound_data.append(value)
    
    return pygame.mixer.Sound(buffer=sound_data)

# Pre-generate explosion sounds for different intensities (1-5 lines)
EXPLOSION_SOUNDS = {}
for i in range(1, 6):
    EXPLOSION_SOUNDS[i] = generate_explosion_sound(i)
    EXPLOSION_SOUNDS[i].set_volume(0.4 + i * 0.1)  # Louder for bigger explosions

def generate_blopper_sound():
    """Generate a bloopy/bubbly sound for partial landing"""
    sample_rate = 22050
    duration = 0.2  # seconds
    samples = int(sample_rate * duration)
    
    sound_data = array.array('h')
    for i in range(samples):
        t = i / sample_rate
        # Rising then falling frequency for "blop" effect
        freq = 150 + 200 * math.sin(math.pi * t / duration)
        decay = math.exp(-t * 10)
        
        # Bubbly sound with frequency modulation
        wave = math.sin(2 * math.pi * freq * t + math.sin(2 * math.pi * 20 * t) * 2)
        value = int(wave * decay * 10000)
        sound_data.append(value)
        sound_data.append(value)
    
    return pygame.mixer.Sound(buffer=sound_data)

def generate_russian_folk_music(seed=None, level=1):
    """Generate pleasant folk music that evolves with game level"""
    if seed is None:
        seed = random.randint(0, 999999)
    
    rng = random.Random(seed)
    sample_rate = 22050
    
    # Pleasant minor pentatonic scale: A C D E G (two octaves)
    scale = [220, 262, 294, 330, 392, 440, 523, 587, 659, 784]
    
    # Bass notes for chord progressions
    bass_i = 110   # A (tonic)
    bass_iv = 147  # D (subdominant)
    bass_v = 165   # E (dominant)
    bass_vi = 175  # F (submediant)
    
    # Generate 4-note melodic phrases
    def generate_phrase(rng, start_idx=2, energy='low'):
        if energy == 'low':
            patterns = [
                [0, 1, 0, 0],      # Gentle, minimal movement
                [0, 2, 1, 0],      # Simple arc
                [1, 0, 1, 0],      # Oscillating
            ]
        elif energy == 'medium':
            patterns = [
                [0, 2, 3, 2],      # Rising arc
                [2, 1, 0, 2],      # Down and up
                [0, 1, 2, 1],      # Climbing
            ]
        else:  # high
            patterns = [
                [2, 3, 4, 3],      # High climax
                [3, 2, 4, 3],      # Exciting leap
                [0, 3, 2, 4],      # Big jump up
            ]
        pattern = rng.choice(patterns)
        phrase = []
        for offset in pattern:
            idx = max(0, min(len(scale) - 1, start_idx + offset))
            phrase.append(scale[idx])
        return phrase
    
    # Choose song structure based on seed (variety)
    structures = [
        ['A', 'A', 'B', 'A'],           # Classic AABA
        ['A', 'B', 'A', 'B'],           # Alternating ABAB
        ['A', 'A', 'B', 'C', 'A'],      # Extended with bridge
        ['A', 'B', 'C', 'B'],           # Through-composed feel
        ['A', 'A', 'A', 'B'],           # Building tension
    ]
    structure = rng.choice(structures)
    
    # Generate phrases for each section
    phrase_a = generate_phrase(rng, start_idx=1, energy='low')
    phrase_b = generate_phrase(rng, start_idx=2, energy='medium')
    phrase_c = generate_phrase(rng, start_idx=3, energy='high')
    
    sections = {'A': phrase_a, 'B': phrase_b, 'C': phrase_c}
    
    # Build full melody from structure
    full_melody = []
    for section in structure:
        full_melody.extend(sections[section])
    
    # Bass progression matching sections
    bass_patterns = {
        'A': [bass_i, bass_i],
        'B': [bass_iv, bass_v],
        'C': [bass_vi, bass_v],
    }
    full_bass = []
    for section in structure:
        full_bass.extend(bass_patterns[section] * 2)  # 4 notes per section
    
    # Tempo: relaxed (75-90 BPM)
    bpm = 75 + rng.random() * 15
    note_duration = 60.0 / bpm
    total_duration = len(full_melody) * note_duration
    
    samples = int(sample_rate * total_duration)
    sound_data = array.array('h')
    
    # Level-based features (unlock progressively)
    has_rhythm = level >= 1        # Basic rhythm always
    has_offbeat = level >= 2       # Off-beat accents
    has_harmony = level >= 3       # Harmony notes
    has_counter = level >= 4       # Counter-melody
    has_fills = level >= 5         # Rhythmic fills
    
    for i in range(samples):
        t = i / sample_rate
        
        # Current note
        note_idx = min(int(t / note_duration), len(full_melody) - 1)
        note_t = (t % note_duration) / note_duration
        
        freq = full_melody[note_idx]
        bass_freq = full_bass[note_idx] if note_idx < len(full_bass) else bass_i
        
        # Smooth envelope
        attack = 0.08
        sustain_end = 0.75
        if note_t < attack:
            envelope = note_t / attack
        elif note_t < sustain_end:
            envelope = 1.0 - (note_t - attack) * 0.08
        else:
            envelope = 0.92 * (1 - (note_t - sustain_end) / (1 - sustain_end))
        envelope = max(0, min(1.0, envelope))
        
        # Main melody (warm tone)
        melody_wave = (
            math.sin(2 * math.pi * freq * t) * 0.40 +
            math.sin(2 * math.pi * freq * 2 * t) * 0.12 +
            math.sin(2 * math.pi * freq * 3 * t) * 0.04
        ) * envelope
        
        # Harmony (third above) - unlocked at level 3
        harmony_wave = 0
        if has_harmony:
            harm_freq = freq * 1.2  # Minor third
            harmony_wave = math.sin(2 * math.pi * harm_freq * t) * 0.08 * envelope
        
        # Counter-melody (fifth below, delayed rhythm) - unlocked at level 4
        counter_wave = 0
        if has_counter:
            counter_t = (t - 0.15) % total_duration  # Delayed
            counter_idx = min(int(counter_t / note_duration), len(full_melody) - 1)
            counter_freq = full_melody[counter_idx] * 0.75  # Fifth below
            counter_env = envelope * 0.6
            counter_wave = math.sin(2 * math.pi * counter_freq * t) * 0.06 * counter_env
        
        # Bass line
        bass_wave = (
            math.sin(2 * math.pi * bass_freq * t) * 0.16 +
            math.sin(2 * math.pi * bass_freq * 2 * t) * 0.05
        )
        # Add fifth for richness
        bass_wave += math.sin(2 * math.pi * bass_freq * 1.5 * t) * 0.04
        
        # Rhythm section
        beat_num = (t * bpm / 60) % 4
        beat_phase = beat_num % 1
        
        # Basic kick on 1 and 3
        kick = 0
        if has_rhythm:
            if beat_phase < 0.06 and (int(beat_num) == 0 or int(beat_num) == 2):
                kick = math.exp(-beat_phase * 60) * 0.12
        
        # Off-beat hi-hat on 2 and 4 - unlocked at level 2
        hihat = 0
        if has_offbeat:
            if beat_phase < 0.03 and (int(beat_num) == 1 or int(beat_num) == 3):
                hihat = math.exp(-beat_phase * 120) * 0.06
        
        # Rhythmic fills every 4 bars - unlocked at level 5
        fill = 0
        if has_fills:
            bar_pos = (note_idx % 16)  # 16 notes = 4 bars
            if bar_pos >= 14:  # Last 2 beats of every 4 bars
                fill_phase = (t * bpm / 60 * 2) % 1  # Double time
                if fill_phase < 0.04:
                    fill = math.exp(-fill_phase * 80) * 0.05
        
        # Mix everything
        total = (melody_wave + harmony_wave + counter_wave + 
                bass_wave + kick + hihat + fill)
        
        value = int(total * 5500)
        value = max(-32000, min(32000, value))
        sound_data.append(value)
        sound_data.append(value)
    
    return pygame.mixer.Sound(buffer=sound_data)

# Pre-generate sounds (static ones)
LANDING_SOUND = generate_landing_sound()
BLOPPER_SOUND = generate_blopper_sound()
LANDING_SOUND.set_volume(0.5)
BLOPPER_SOUND.set_volume(0.4)

# Music will be generated dynamically per game
CURRENT_MUSIC = None

def to_grayscale(color):
    """Convert a color to grayscale (monochrome) - lighter version for visibility"""
    gray = int(0.299 * color[0] + 0.587 * color[1] + 0.114 * color[2])
    # Boost the gray value to make it lighter (minimum 120, scale up darker values)
    light_gray = max(140, min(255, int(gray * 0.5 + 140)))
    return (light_gray, light_gray, light_gray)

def brighten_color(color, factor=1.5):
    """Brighten a color by a factor"""
    return tuple(min(255, int(c * factor)) for c in color)

# Play level constants
PLAY_LEVEL_NORMAL = 0
PLAY_LEVEL_ADVANCED = 1
PLAY_LEVEL_BOULDER = 2
PLAY_LEVEL_NAMES = {PLAY_LEVEL_NORMAL: "NORMAL", PLAY_LEVEL_ADVANCED: "ADVANCED", PLAY_LEVEL_BOULDER: "BOULDER"}
PLAY_LEVEL_COLORS = {PLAY_LEVEL_NORMAL: (100, 255, 100), PLAY_LEVEL_ADVANCED: (255, 255, 100), PLAY_LEVEL_BOULDER: (255, 100, 100)}

def generate_random_shape(min_cells=2, max_cells=4, min_size=None, max_size=None):
    """Generate a random block shape with cell count and/or size constraints"""
    
    # Determine grid size based on constraints
    if max_size is not None:
        grid_size = max_size
    else:
        # Size grid to fit max_cells in a line (allows long shapes)
        grid_size = max_cells
    
    if min_size is not None:
        grid_size = max(grid_size, min_size)
    
    # Try multiple times to generate a valid shape
    for _ in range(20):
        shape = [[0] * grid_size for _ in range(grid_size)]
        
        # Start with one cell in the center and grow randomly
        start_x, start_y = grid_size // 2, grid_size // 2
        filled = {(start_x, start_y)}
        shape[start_y][start_x] = 1
        
        # Pick target cell count
        target_cells = random.randint(min_cells, max_cells)
        
        # Grow the shape by adding adjacent cells
        max_attempts = grid_size * grid_size * 10
        for _ in range(max_attempts):
            if len(filled) >= target_cells:
                break
            
            # Pick a random filled cell and try to grow from it
            cx, cy = random.choice(list(filled))
            directions = [(0, 1), (0, -1), (1, 0), (-1, 0)]
            random.shuffle(directions)
            
            for dx, dy in directions:
                nx, ny = cx + dx, cy + dy
                if 0 <= nx < grid_size and 0 <= ny < grid_size and (nx, ny) not in filled:
                    shape[ny][nx] = 1
                    filled.add((nx, ny))
                    break
        
        # If we need minimum size, keep growing until we reach it
        if min_size is not None:
            min_x = min(x for x, y in filled)
            max_x = max(x for x, y in filled)
            min_y = min(y for x, y in filled)
            max_y = max(y for x, y in filled)
            current_width = max_x - min_x + 1
            current_height = max_y - min_y + 1
            
            while current_width < min_size or current_height < min_size:
                edge_cells = []
                for x, y in filled:
                    for dx, dy in [(0, 1), (0, -1), (1, 0), (-1, 0)]:
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < grid_size and 0 <= ny < grid_size and (nx, ny) not in filled:
                            edge_cells.append((nx, ny))
                
                if not edge_cells:
                    break
                
                nx, ny = random.choice(edge_cells)
                shape[ny][nx] = 1
                filled.add((nx, ny))
                
                min_x = min(x for x, y in filled)
                max_x = max(x for x, y in filled)
                min_y = min(y for x, y in filled)
                max_y = max(y for x, y in filled)
                current_width = max_x - min_x + 1
                current_height = max_y - min_y + 1
        
        # Trim empty rows and columns
        while shape and all(cell == 0 for cell in shape[0]):
            shape.pop(0)
        while shape and all(cell == 0 for cell in shape[-1]):
            shape.pop()
        while shape and shape[0] and all(row[0] == 0 for row in shape):
            for row in shape:
                row.pop(0)
        while shape and shape[0] and all(row[-1] == 0 for row in shape):
            for row in shape:
                row.pop()
        
        if not shape:
            continue
        
        # Verify constraints
        cell_count = sum(sum(row) for row in shape)
        height = len(shape)
        width = len(shape[0]) if shape else 0
        
        # Check cell count constraints
        if cell_count < min_cells or cell_count > max_cells:
            continue
        
        # Check size constraints
        if min_size is not None and (width < min_size or height < min_size):
            continue
        if max_size is not None and (width > max_size or height > max_size):
            continue
        
        return shape
    
    # Fallback: create a simple line with min_cells
    return [[1] * min_cells]

def rotate_shape(shape, clockwise=True):
    """Rotate the shape 90 degrees"""
    if clockwise:
        return [list(row) for row in zip(*shape[::-1])]
    else:
        return [list(row) for row in zip(*shape)][::-1]

class Block:
    def __init__(self, shape=None, color=None, direction=None, num_directions=4, 
                 min_cells=2, max_cells=4, min_size=None, max_size=None):
        if shape:
            self.shape = shape
        else:
            self.shape = generate_random_shape(min_cells, max_cells, min_size, max_size)
        
        self.color = color if color else random.choice(BLOCK_COLORS)
        # Only use directions up to num_directions
        # 1=DOWN, 2=DOWN+UP, 3=DOWN+UP+LEFT, 4=all
        if direction is not None:
            self.direction = direction
        else:
            available_directions = [DOWN, UP, LEFT, RIGHT][:num_directions]
            self.direction = random.choice(available_directions)
        self.x = 0
        self.y = 0
    
    def width(self):
        return len(self.shape[0]) if self.shape else 0
    
    def height(self):
        return len(self.shape)
    
    def rotate(self, clockwise=True):
        self.shape = rotate_shape(self.shape, clockwise)

class Game:
    def __init__(self):
        self.screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))
        pygame.display.set_caption("Multi-Directional Tetris")
        self.clock = pygame.time.Clock()
        self.font = pygame.font.Font(None, 36)
        self.small_font = pygame.font.Font(None, 24)
        self.reset_game()
    
    def reset_game(self):
        self.grid: list[list[Optional[tuple[int, int, int]]]] = [[None] * GRID_WIDTH for _ in range(GRID_HEIGHT)]
        self.score = 0
        self.lines_cleared = 0
        self.level = 1
        self.game_over = False
        self.paused = False
        if not hasattr(self, 'music_enabled'):
            self.music_enabled = True
        if not hasattr(self, 'effects_enabled'):
            self.effects_enabled = True
        if not hasattr(self, 'play_level'):
            self.play_level = PLAY_LEVEL_NORMAL
        if not hasattr(self, 'num_directions'):
            self.num_directions = 4  # Default to all 4 directions
        
        # Set block parameters based on play level
        if self.play_level == PLAY_LEVEL_NORMAL:
            # Normal: 2-4 total cells
            self.min_cells = 2
            self.max_cells = 4
            self.min_size = None
            self.max_size = None
        elif self.play_level == PLAY_LEVEL_ADVANCED:
            # Advanced: 3-6 total cells, max 4 side
            self.min_cells = 3
            self.max_cells = 6
            self.min_size = None
            self.max_size = 4
        else:  # BOULDER
            # Boulder: 2-3 side (bounding box)
            self.min_cells = 4  # At least 4 cells to span 2x2
            self.max_cells = 9  # Up to 3x3 filled
            self.min_size = 2
            self.max_size = 3
        
        self.next_block = Block(num_directions=self.num_directions, 
                                min_cells=self.min_cells, max_cells=self.max_cells,
                                min_size=self.min_size, max_size=self.max_size)
        self.spawn_new_block()
        self.fall_time = 0
        self.base_fall_speed = 500  # milliseconds
        self.fall_speed = self.base_fall_speed
        # Animation state for line clearing
        self.clearing_lines = []  # List of (type, index) - type is 'row' or 'col'
        self.clear_animation_time = 0
        self.clear_animation_duration = 200  # milliseconds for flash effect
        # Start music if enabled
        if self.music_enabled:
            self.start_music()
    
    def start_music(self):
        """Start a new procedurally generated background music loop"""
        global CURRENT_MUSIC
        # Stop any existing music first to prevent overlap
        self.stop_music()
        # Generate a new unique tune based on current level
        CURRENT_MUSIC = generate_russian_folk_music(level=self.level)
        CURRENT_MUSIC.set_volume(0.3)
        CURRENT_MUSIC.play(loops=-1)  # -1 = infinite loop
    
    def stop_music(self):
        """Stop the background music"""
        global CURRENT_MUSIC
        if CURRENT_MUSIC is not None:
            CURRENT_MUSIC.stop()
            CURRENT_MUSIC = None
    
    def toggle_music(self):
        """Toggle music on/off"""
        self.music_enabled = not self.music_enabled
        if self.music_enabled:
            self.start_music()
        else:
            self.stop_music()
    
    def toggle_effects(self):
        """Toggle sound effects on/off"""
        self.effects_enabled = not self.effects_enabled
    
    def toggle_pause(self):
        """Toggle pause state"""
        self.paused = not self.paused
    
    def cycle_play_level(self):
        """Cycle through play levels: Normal -> Advanced -> Boulder -> Normal"""
        self.play_level = (self.play_level + 1) % 3
        self.reset_game()  # This will regenerate music
    
    def get_spawn_position(self, block):
        """Calculate spawn position based on block direction (at edge, away from pile)"""
        direction = block.direction
        
        if direction == DOWN:  # Block moves down, spawn at top
            x = GRID_WIDTH // 2 - block.width() // 2
            y = 0
            
        elif direction == UP:  # Block moves up, spawn at bottom
            x = GRID_WIDTH // 2 - block.width() // 2
            y = GRID_HEIGHT - block.height()
            
        elif direction == RIGHT:  # Block moves right, spawn at left
            x = 0
            y = GRID_HEIGHT // 2 - block.height() // 2
            
        elif direction == LEFT:  # Block moves left, spawn at right
            x = GRID_WIDTH - block.width()
            y = GRID_HEIGHT // 2 - block.height() // 2
        
        return x, y
    
    def find_valid_spawn_position(self, block):
        """Find a valid spawn position, searching for free space between piles"""
        direction = block.direction
        base_x, base_y = self.get_spawn_position(block)
        
        # Try the default position first
        if self.can_spawn_block(block, base_x, base_y):
            return base_x, base_y, True
        
        # Search for a valid position along the spawn edge
        if direction == DOWN:
            # Try moving the spawn point down (into the grid) to find space
            for y in range(0, GRID_HEIGHT - block.height() + 1):
                for x_offset in range(max(GRID_WIDTH // 2, block.width())):
                    for x in [base_x - x_offset, base_x + x_offset]:
                        if 0 <= x <= GRID_WIDTH - block.width():
                            if self.can_spawn_block(block, x, y):
                                return x, y, True
                                
        elif direction == UP:
            # Try moving the spawn point up to find space
            for y in range(GRID_HEIGHT - block.height(), -1, -1):
                for x_offset in range(max(GRID_WIDTH // 2, block.width())):
                    for x in [base_x - x_offset, base_x + x_offset]:
                        if 0 <= x <= GRID_WIDTH - block.width():
                            if self.can_spawn_block(block, x, y):
                                return x, y, True
                                
        elif direction == RIGHT:
            # Try moving the spawn point right to find space
            for x in range(0, GRID_WIDTH - block.width() + 1):
                for y_offset in range(max(GRID_HEIGHT // 2, block.height())):
                    for y in [base_y - y_offset, base_y + y_offset]:
                        if 0 <= y <= GRID_HEIGHT - block.height():
                            if self.can_spawn_block(block, x, y):
                                return x, y, True
                                
        elif direction == LEFT:
            # Try moving the spawn point left to find space
            for x in range(GRID_WIDTH - block.width(), -1, -1):
                for y_offset in range(max(GRID_HEIGHT // 2, block.height())):
                    for y in [base_y - y_offset, base_y + y_offset]:
                        if 0 <= y <= GRID_HEIGHT - block.height():
                            if self.can_spawn_block(block, x, y):
                                return x, y, True
        
        # No valid position found
        return base_x, base_y, False
    
    def can_spawn_block(self, block, x, y):
        """Check if there's room to spawn the block (no overlap with existing pieces)"""
        for row_idx, row in enumerate(block.shape):
            for col_idx, cell in enumerate(row):
                if cell:
                    check_x = x + col_idx
                    check_y = y + row_idx
                    # Check if position is within bounds
                    if check_x < 0 or check_x >= GRID_WIDTH:
                        return False
                    if check_y < 0 or check_y >= GRID_HEIGHT:
                        return False
                    # Check if position is already occupied
                    if self.grid[check_y][check_x] is not None:
                        return False
        return True
    
    def spawn_new_block(self):
        self.current_block = self.next_block
        self.next_block = Block(num_directions=self.num_directions,
                                min_cells=self.min_cells, max_cells=self.max_cells,
                                min_size=self.min_size, max_size=self.max_size)
        
        # Find a valid spawn position, searching the entire spawn area
        x, y, can_spawn = self.find_valid_spawn_position(self.current_block)
        self.current_block.x = x
        self.current_block.y = y
        
        # Game over only if there's absolutely no room to spawn anywhere
        if not can_spawn:
            self.game_over = True
    
    def is_valid_position(self, block, offset_x=0, offset_y=0):
        """Check if block position is valid"""
        for row_idx, row in enumerate(block.shape):
            for col_idx, cell in enumerate(row):
                if cell:
                    new_x = block.x + col_idx + offset_x
                    new_y = block.y + row_idx + offset_y
                    
                    if new_x < 0 or new_x >= GRID_WIDTH:
                        return False
                    if new_y < 0 or new_y >= GRID_HEIGHT:
                        return False
                    if self.grid[new_y][new_x] is not None:
                        return False
        return True
    
    def lock_block(self):
        """Lock the current block into the grid - converts to monochrome"""
        mono_color = to_grayscale(self.current_block.color)
        for row_idx, row in enumerate(self.current_block.shape):
            for col_idx, cell in enumerate(row):
                if cell:
                    x = self.current_block.x + col_idx
                    y = self.current_block.y + row_idx
                    if 0 <= x < GRID_WIDTH and 0 <= y < GRID_HEIGHT:
                        self.grid[y][x] = mono_color
        
        # Check if block landed solidly or partially
        if self.effects_enabled:
            if self.is_solid_landing():
                LANDING_SOUND.play()
            else:
                BLOPPER_SOUND.play()
        
        self.check_and_start_clear_animation()
        if not self.clearing_lines:
            self.spawn_new_block()
    
    def is_solid_landing(self):
        """Check if the block landed with all bottom surfaces touching ground or other blocks"""
        direction = self.current_block.direction
        block = self.current_block
        
        # Find the "bottom" cells based on movement direction
        if direction == DOWN:
            # Check cells at the bottom of each column of the shape
            for col_idx in range(len(block.shape[0])):
                # Find the lowest cell in this column
                lowest_row = -1
                for row_idx in range(len(block.shape)):
                    if block.shape[row_idx][col_idx]:
                        lowest_row = row_idx
                if lowest_row >= 0:
                    x = block.x + col_idx
                    y = block.y + lowest_row
                    # Check if there's ground or block below
                    if y < GRID_HEIGHT - 1 and self.grid[y + 1][x] is None:
                        return False
        elif direction == UP:
            # Check cells at the top of each column
            for col_idx in range(len(block.shape[0])):
                highest_row = -1
                for row_idx in range(len(block.shape)):
                    if block.shape[row_idx][col_idx]:
                        highest_row = row_idx
                        break
                if highest_row >= 0:
                    x = block.x + col_idx
                    y = block.y + highest_row
                    if y > 0 and self.grid[y - 1][x] is None:
                        return False
        elif direction == RIGHT:
            # Check cells at the right of each row
            for row_idx in range(len(block.shape)):
                rightmost_col = -1
                for col_idx in range(len(block.shape[0])):
                    if block.shape[row_idx][col_idx]:
                        rightmost_col = col_idx
                if rightmost_col >= 0:
                    x = block.x + rightmost_col
                    y = block.y + row_idx
                    if x < GRID_WIDTH - 1 and self.grid[y][x + 1] is None:
                        return False
        elif direction == LEFT:
            # Check cells at the left of each row
            for row_idx in range(len(block.shape)):
                leftmost_col = -1
                for col_idx in range(len(block.shape[0])):
                    if block.shape[row_idx][col_idx]:
                        leftmost_col = col_idx
                        break
                if leftmost_col >= 0:
                    x = block.x + leftmost_col
                    y = block.y + row_idx
                    if x > 0 and self.grid[y][x - 1] is None:
                        return False
        return True
    
    def check_and_start_clear_animation(self):
        """Check for complete lines and start the flash animation"""
        self.clearing_lines = []
        
        # Check horizontal lines (rows)
        for y in range(GRID_HEIGHT):
            if all(self.grid[y][x] is not None for x in range(GRID_WIDTH)):
                self.clearing_lines.append(('row', y))
        
        # Check vertical lines (columns)
        for x in range(GRID_WIDTH):
            if all(self.grid[y][x] is not None for y in range(GRID_HEIGHT)):
                self.clearing_lines.append(('col', x))
        
        if self.clearing_lines:
            self.clear_animation_time = self.clear_animation_duration
            # Brighten the lines that will be cleared
            self.brighten_clearing_lines()
    
    def brighten_clearing_lines(self):
        """Brighten the cells in lines that are about to be cleared"""
        for line_type, index in self.clearing_lines:
            if line_type == 'row':
                for x in range(GRID_WIDTH):
                    if self.grid[index][x] is not None:
                        self.grid[index][x] = brighten_color(self.grid[index][x], 2.0)
            elif line_type == 'col':
                for y in range(GRID_HEIGHT):
                    if self.grid[y][index] is not None:
                        self.grid[y][index] = brighten_color(self.grid[y][index], 2.0)
    
    def finish_clear_lines(self):
        """Actually clear the lines after animation and calculate score"""
        if not self.clearing_lines:
            return
        
        total_lines_cleared = len(self.clearing_lines)
        
        # Clear only the specific rows/columns that were detected as complete
        for line_type, index in self.clearing_lines:
            if line_type == 'row':
                for x in range(GRID_WIDTH):
                    self.grid[index][x] = None
            elif line_type == 'col':
                for y in range(GRID_HEIGHT):
                    self.grid[y][index] = None
        
        # Collapse blocks toward their respective edges
        self.collapse_all_directions()
        
        if total_lines_cleared > 0:
            self.lines_cleared += total_lines_cleared
            
            # Play explosion sound proportional to lines cleared
            if self.effects_enabled:
                explosion_intensity = min(5, total_lines_cleared)
                EXPLOSION_SOUNDS[explosion_intensity].play()
            
            # Exponential scoring
            points = 0
            for i in range(total_lines_cleared):
                points += 100 * (2 ** i)
            self.score += points
            
            # Level up every 5 lines
            new_level = (self.lines_cleared // 5) + 1
            if new_level > self.level:
                self.level = new_level
                self.fall_speed = int(self.base_fall_speed * (0.9 ** (self.level - 1)))
                # Regenerate music with new elements for this level
                if self.music_enabled:
                    self.start_music()
        
        self.clearing_lines = []
        self.spawn_new_block()
    
    def collapse_all_directions(self):
        """Collapse blocks towards their respective direction edges to fill empty spaces"""
        available_directions = [DOWN, UP, LEFT, RIGHT][:self.num_directions]
        
        # We need to handle each quadrant/section based on active directions
        # For simplicity, we'll do multiple passes to settle everything
        
        for _ in range(max(GRID_WIDTH, GRID_HEIGHT)):  # Multiple passes to fully settle
            if DOWN in available_directions:
                self.collapse_down()
            if UP in available_directions:
                self.collapse_up()
            if RIGHT in available_directions:
                self.collapse_right()
            if LEFT in available_directions:
                self.collapse_left()
    
    def collapse_down(self):
        """Collapse blocks downward (for DOWN direction) - bottom half of grid"""
        mid_y = GRID_HEIGHT // 2
        # Only affect bottom half for DOWN direction
        for x in range(GRID_WIDTH):
            # Collect non-empty cells in bottom half
            cells = []
            for y in range(mid_y, GRID_HEIGHT):
                if self.grid[y][x] is not None:
                    cells.append(self.grid[y][x])
                    self.grid[y][x] = None
            # Place them at the bottom
            for i, color in enumerate(reversed(cells)):
                self.grid[GRID_HEIGHT - 1 - i][x] = color
    
    def collapse_up(self):
        """Collapse blocks upward (for UP direction) - top half of grid"""
        mid_y = GRID_HEIGHT // 2
        # Only affect top half for UP direction
        for x in range(GRID_WIDTH):
            # Collect non-empty cells in top half
            cells = []
            for y in range(0, mid_y):
                if self.grid[y][x] is not None:
                    cells.append(self.grid[y][x])
                    self.grid[y][x] = None
            # Place them at the top
            for i, color in enumerate(cells):
                self.grid[i][x] = color
    
    def collapse_right(self):
        """Collapse blocks rightward (for RIGHT direction) - right half of grid"""
        mid_x = GRID_WIDTH // 2
        # Only affect right half for RIGHT direction
        for y in range(GRID_HEIGHT):
            # Collect non-empty cells in right half
            cells = []
            for x in range(mid_x, GRID_WIDTH):
                if self.grid[y][x] is not None:
                    cells.append(self.grid[y][x])
                    self.grid[y][x] = None
            # Place them at the right
            for i, color in enumerate(reversed(cells)):
                self.grid[y][GRID_WIDTH - 1 - i] = color
    
    def collapse_left(self):
        """Collapse blocks leftward (for LEFT direction) - left half of grid"""
        mid_x = GRID_WIDTH // 2
        # Only affect left half for LEFT direction
        for y in range(GRID_HEIGHT):
            # Collect non-empty cells in left half
            cells = []
            for x in range(0, mid_x):
                if self.grid[y][x] is not None:
                    cells.append(self.grid[y][x])
                    self.grid[y][x] = None
            # Place them at the left
            for i, color in enumerate(cells):
                self.grid[y][i] = color
    
    def move_block(self, dx, dy):
        """Move block by offset"""
        if self.is_valid_position(self.current_block, dx, dy):
            self.current_block.x += dx
            self.current_block.y += dy
            return True
        return False
    
    def auto_move(self):
        """Move block in its designated direction"""
        direction = self.current_block.direction
        
        if direction == DOWN:
            dx, dy = 0, 1
        elif direction == UP:
            dx, dy = 0, -1
        elif direction == RIGHT:
            dx, dy = 1, 0
        elif direction == LEFT:
            dx, dy = -1, 0
        
        if not self.move_block(dx, dy):
            self.lock_block()
    
    def rotate_block(self, clockwise=True):
        """Rotate the current block"""
        original_shape = self.current_block.shape
        self.current_block.rotate(clockwise)
        
        # Wall kick - try to adjust position if rotation causes collision
        if not self.is_valid_position(self.current_block):
            # Try shifting
            for offset in [(1, 0), (-1, 0), (0, 1), (0, -1), (2, 0), (-2, 0)]:
                if self.is_valid_position(self.current_block, offset[0], offset[1]):
                    self.current_block.x += offset[0]
                    self.current_block.y += offset[1]
                    return
            # Revert if no valid position found
            self.current_block.shape = original_shape
    
    def hard_drop(self):
        """Instantly drop the block to its final position"""
        direction = self.current_block.direction
        
        if direction == DOWN:
            dx, dy = 0, 1
        elif direction == UP:
            dx, dy = 0, -1
        elif direction == RIGHT:
            dx, dy = 1, 0
        elif direction == LEFT:
            dx, dy = -1, 0
        
        while self.move_block(dx, dy):
            self.score += 1
        
        self.lock_block()
    
    def draw_grid(self):
        """Draw the game grid"""
        # Draw background
        pygame.draw.rect(self.screen, DARK_GRAY, 
                        (0, 0, GRID_WIDTH * CELL_SIZE, GRID_HEIGHT * CELL_SIZE))
        
        # Draw grid lines
        for x in range(GRID_WIDTH + 1):
            pygame.draw.line(self.screen, GRAY, 
                           (x * CELL_SIZE, 0), 
                           (x * CELL_SIZE, GRID_HEIGHT * CELL_SIZE))
        for y in range(GRID_HEIGHT + 1):
            pygame.draw.line(self.screen, GRAY, 
                           (0, y * CELL_SIZE), 
                           (GRID_WIDTH * CELL_SIZE, y * CELL_SIZE))
        
        # Draw placed blocks
        for y in range(GRID_HEIGHT):
            for x in range(GRID_WIDTH):
                color = self.grid[y][x]
                if color is not None:
                    pygame.draw.rect(self.screen, color,
                                   (x * CELL_SIZE + 1, y * CELL_SIZE + 1,
                                    CELL_SIZE - 2, CELL_SIZE - 2))
    
    def draw_block(self, block, offset_x=0, offset_y=0, scale=1):
        """Draw a block"""
        for row_idx, row in enumerate(block.shape):
            for col_idx, cell in enumerate(row):
                if cell:
                    x = (block.x + col_idx) * CELL_SIZE * scale + offset_x
                    y = (block.y + row_idx) * CELL_SIZE * scale + offset_y
                    pygame.draw.rect(self.screen, block.color,
                                   (x + 1, y + 1, 
                                    CELL_SIZE * scale - 2, CELL_SIZE * scale - 2))
    
    def draw_ghost(self):
        """Draw ghost piece showing where block will land"""
        ghost = Block(self.current_block.shape, self.current_block.color, 
                     self.current_block.direction)
        ghost.x = self.current_block.x
        ghost.y = self.current_block.y
        
        direction = ghost.direction
        if direction == DOWN:
            dx, dy = 0, 1
        elif direction == UP:
            dx, dy = 0, -1
        elif direction == RIGHT:
            dx, dy = 1, 0
        elif direction == LEFT:
            dx, dy = -1, 0
        
        while self.is_valid_position(ghost, dx, dy):
            ghost.x += dx
            ghost.y += dy
        
        # Draw ghost with transparency
        for row_idx, row in enumerate(ghost.shape):
            for col_idx, cell in enumerate(row):
                if cell:
                    x = (ghost.x + col_idx) * CELL_SIZE
                    y = (ghost.y + row_idx) * CELL_SIZE
                    ghost_color = tuple(c // 3 for c in ghost.color)
                    pygame.draw.rect(self.screen, ghost_color,
                                   (x + 1, y + 1, CELL_SIZE - 2, CELL_SIZE - 2), 2)
    
    def draw_sidebar(self):
        """Draw the sidebar with score and next block"""
        sidebar_x = GRID_WIDTH * CELL_SIZE
        
        # Background
        pygame.draw.rect(self.screen, BLACK, 
                        (sidebar_x, 0, SIDEBAR_WIDTH, SCREEN_HEIGHT))
        pygame.draw.line(self.screen, WHITE, 
                        (sidebar_x, 0), (sidebar_x, SCREEN_HEIGHT), 2)
        
        # Score
        score_text = self.font.render("Score", True, WHITE)
        self.screen.blit(score_text, (sidebar_x + 10, 20))
        score_value = self.font.render(str(self.score), True, WHITE)
        self.screen.blit(score_value, (sidebar_x + 10, 50))
        
        # Lines
        lines_text = self.small_font.render(f"Lines: {self.lines_cleared}", True, WHITE)
        self.screen.blit(lines_text, (sidebar_x + 10, 90))
        
        # Level
        level_text = self.small_font.render(f"Level: {self.level}", True, WHITE)
        self.screen.blit(level_text, (sidebar_x + 10, 115))
        
        # Directions
        dir_count_text = self.small_font.render(f"Dirs: {self.num_directions}", True, GRAY)
        self.screen.blit(dir_count_text, (sidebar_x + 80, 115))
        
        # Play level indicator
        level_name = PLAY_LEVEL_NAMES[self.play_level]
        level_color = PLAY_LEVEL_COLORS[self.play_level]
        play_level_text = self.small_font.render(level_name, True, level_color)
        self.screen.blit(play_level_text, (sidebar_x + 10, 135))
        
        # Next block
        next_text = self.font.render("Next", True, WHITE)
        self.screen.blit(next_text, (sidebar_x + 10, 140))
        
        # Draw next block preview
        preview_x = sidebar_x + 20
        preview_y = 180
        preview_scale = 0.6
        
        for row_idx, row in enumerate(self.next_block.shape):
            for col_idx, cell in enumerate(row):
                if cell:
                    x = preview_x + col_idx * CELL_SIZE * preview_scale
                    y = preview_y + row_idx * CELL_SIZE * preview_scale
                    pygame.draw.rect(self.screen, self.next_block.color,
                                   (x, y, CELL_SIZE * preview_scale - 2, 
                                    CELL_SIZE * preview_scale - 2))
        
        # Direction hint with arrow
        direction_text = self.font.render(
            DIRECTION_ARROWS[self.next_block.direction], True, WHITE)
        self.screen.blit(direction_text, (sidebar_x + 60, 280))
        
        dir_name = self.small_font.render(
            DIRECTION_NAMES[self.next_block.direction], True, GRAY)
        self.screen.blit(dir_name, (sidebar_x + 40, 310))
        
        # Controls
        controls_y = 360
        controls = [
            "Controls:",
            "Arrows Move",
            "Z/X Rotate",
            "Space Drop",
            "P Pause",
            "M Music" + (" ON" if self.music_enabled else " OFF"),
            "N Effects" + (" ON" if self.effects_enabled else " OFF"),
            "L Level",
            "R Restart",
            "Q Quit"
        ]
        for i, text in enumerate(controls):
            ctrl_text = self.small_font.render(text, True, GRAY)
            self.screen.blit(ctrl_text, (sidebar_x + 10, controls_y + i * 20))
    
    def draw_game_over(self):
        """Draw game over screen"""
        overlay = pygame.Surface((SCREEN_WIDTH, SCREEN_HEIGHT))
        overlay.set_alpha(180)
        overlay.fill(BLACK)
        self.screen.blit(overlay, (0, 0))
        
        game_over_text = self.font.render("GAME OVER", True, WHITE)
        text_rect = game_over_text.get_rect(center=(GRID_WIDTH * CELL_SIZE // 2, 
                                                     SCREEN_HEIGHT // 2 - 30))
        self.screen.blit(game_over_text, text_rect)
        
        score_text = self.font.render(f"Score: {self.score}", True, WHITE)
        score_rect = score_text.get_rect(center=(GRID_WIDTH * CELL_SIZE // 2, 
                                                  SCREEN_HEIGHT // 2 + 10))
        self.screen.blit(score_text, score_rect)
        
        restart_text = self.small_font.render("Press R to restart", True, GRAY)
        restart_rect = restart_text.get_rect(center=(GRID_WIDTH * CELL_SIZE // 2, 
                                                      SCREEN_HEIGHT // 2 + 50))
        self.screen.blit(restart_text, restart_rect)
    
    def draw_pause(self):
        """Draw pause overlay"""
        overlay = pygame.Surface((SCREEN_WIDTH, SCREEN_HEIGHT))
        overlay.set_alpha(150)
        overlay.fill(BLACK)
        self.screen.blit(overlay, (0, 0))
        
        pause_text = self.font.render("PAUSED", True, WHITE)
        text_rect = pause_text.get_rect(center=(GRID_WIDTH * CELL_SIZE // 2, 
                                                 SCREEN_HEIGHT // 2))
        self.screen.blit(pause_text, text_rect)
        
        resume_text = self.small_font.render("Press P to resume", True, GRAY)
        resume_rect = resume_text.get_rect(center=(GRID_WIDTH * CELL_SIZE // 2, 
                                                    SCREEN_HEIGHT // 2 + 40))
        self.screen.blit(resume_text, resume_rect)
    
    def run(self):
        """Main game loop"""
        running = True
        
        while running:
            dt = self.clock.tick(60)
            
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    running = False
                
                if event.type == pygame.KEYDOWN:
                    # Global controls (work anytime)
                    if event.key == pygame.K_q or event.key == pygame.K_ESCAPE:
                        running = False
                    elif event.key == pygame.K_m:
                        self.toggle_music()
                    elif event.key == pygame.K_n:
                        self.toggle_effects()
                    elif event.key == pygame.K_p:
                        self.toggle_pause()
                    elif event.key == pygame.K_r:
                        self.reset_game()
                    elif event.key == pygame.K_l:
                        self.cycle_play_level()
                    
                    # Direction level selector (1-4)
                    if event.key == pygame.K_1:
                        self.num_directions = 1
                        self.reset_game()
                    elif event.key == pygame.K_2:
                        self.num_directions = 2
                        self.reset_game()
                    elif event.key == pygame.K_3:
                        self.num_directions = 3
                        self.reset_game()
                    elif event.key == pygame.K_4:
                        self.num_directions = 4
                        self.reset_game()
                    
                    # Game controls (only when not paused or game over)
                    if not self.game_over and not self.paused:
                        direction = self.current_block.direction
                        # Reverse direction arrow rotates, others move
                        if event.key == pygame.K_LEFT:
                            if direction == RIGHT:
                                self.rotate_block(clockwise=True)
                            else:
                                self.move_block(-1, 0)
                        elif event.key == pygame.K_RIGHT:
                            if direction == LEFT:
                                self.rotate_block(clockwise=True)
                            else:
                                self.move_block(1, 0)
                        elif event.key == pygame.K_UP:
                            if direction == DOWN:
                                self.rotate_block(clockwise=True)
                            else:
                                self.move_block(0, -1)
                        elif event.key == pygame.K_DOWN:
                            if direction == UP:
                                self.rotate_block(clockwise=True)
                            else:
                                self.move_block(0, 1)
                        elif event.key == pygame.K_z:
                            self.rotate_block(clockwise=False)
                        elif event.key == pygame.K_x:
                            self.rotate_block(clockwise=True)
                        elif event.key == pygame.K_SPACE:
                            self.hard_drop()
            
            if not self.game_over and not self.paused:
                # Handle line clear animation
                if self.clearing_lines:
                    self.clear_animation_time -= dt
                    if self.clear_animation_time <= 0:
                        self.finish_clear_lines()
                else:
                    # Auto-move based on direction
                    self.fall_time += dt
                    if self.fall_time >= self.fall_speed:
                        self.fall_time = 0
                        self.auto_move()
            
            # Draw everything
            self.screen.fill(BLACK)
            self.draw_grid()
            
            if not self.game_over and not self.clearing_lines:
                self.draw_ghost()
                self.draw_block(self.current_block)
            
            self.draw_sidebar()
            
            if self.paused and not self.game_over:
                self.draw_pause()
            
            if self.game_over:
                self.draw_game_over()
            
            pygame.display.flip()
        
        self.stop_music()
        pygame.quit()

# Run the game
if __name__ == "__main__":
    game = Game()
    game.run()
