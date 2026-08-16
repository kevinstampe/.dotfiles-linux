/* Danish 3-layer layout modelled on the iOS Danish keyboard.
 *
 * Layers: Letters (default) -> Numbers -> Symbols, switched explicitly with
 * 123 / #+= / ABC keys rather than wvkbd's cycling NextLayer, matching iOS.
 *
 * Deviations from iOS, all deliberate:
 *   - iOS `kr` types two characters; a Copy key emits exactly one codepoint,
 *     so that slot is a backtick instead (otherwise unreachable on any layer).
 *   - Esc added to every bottom row, and the Symbols layer's redundant
 *     punctuation row (a duplicate of the Numbers layer's) is arrow keys.
 *   - ⌄ hides the keyboard (Hide key type, see the build script's C patch).
 *   - No Ctrl key. Shift+space still sends Tab via SHIFT_SPACE_IS_TAB.
 *
 * Å Æ Ø and every symbol are Copy keys, so they emit their literal codepoint
 * regardless of the system keymap. Letters, digits, Esc, arrows, Enter, Space
 * and Backspace are Code keys so real modifiers still work.
 */

/* constants */
/* how tall the keyboard should be by default (can be overriden) */
#define KBD_PIXEL_HEIGHT 250

/* how tall the keyboard should be by default (can be overriden) */
#define KBD_PIXEL_LANDSCAPE_HEIGHT 120

/* spacing around each key */
#define KBD_KEY_BORDER 2

/* layout declarations */
enum layout_id {
	Letters = 0,
	Numbers,
	Symbols,
	/* keyboard.c refers to `Index` unconditionally (it is the layout the
	 * compose key falls back to), so it has to exist even though nothing in
	 * this set reaches it. */
	Index,
	NumLayouts
};

static struct key keys_letters[], keys_numbers[], keys_symbols[], keys_index[];

static struct layout layouts[NumLayouts] = {
  /* keys, keymap name, layout name, is this an alphabetical/primary layout */
  [Letters] = {keys_letters, "latin", "letters", true},
  [Numbers] = {keys_numbers, "latin", "numbers", false},
  [Symbols] = {keys_symbols, "latin", "symbols", false},
  [Index]   = {keys_index,   "latin", "index",   false},
};

/* {label, shift_label, width, type, code, layout, code_mod, scheme, reset_mod} */

static struct key keys_letters[] = {
  {"q", "Q", 1.0, Code, KEY_Q},
  {"w", "W", 1.0, Code, KEY_W},
  {"e", "E", 1.0, Code, KEY_E},
  {"r", "R", 1.0, Code, KEY_R},
  {"t", "T", 1.0, Code, KEY_T},
  {"y", "Y", 1.0, Code, KEY_Y},
  {"u", "U", 1.0, Code, KEY_U},
  {"i", "I", 1.0, Code, KEY_I},
  {"o", "O", 1.0, Code, KEY_O},
  {"p", "P", 1.0, Code, KEY_P},
  {"å", "Å", 1.0, Copy, 0x00E5, 0, 0x00C5},
  {"", "", 0.0, EndRow},

  {"a", "A", 1.0, Code, KEY_A},
  {"s", "S", 1.0, Code, KEY_S},
  {"d", "D", 1.0, Code, KEY_D},
  {"f", "F", 1.0, Code, KEY_F},
  {"g", "G", 1.0, Code, KEY_G},
  {"h", "H", 1.0, Code, KEY_H},
  {"j", "J", 1.0, Code, KEY_J},
  {"k", "K", 1.0, Code, KEY_K},
  {"l", "L", 1.0, Code, KEY_L},
  {"æ", "Æ", 1.0, Copy, 0x00E6, 0, 0x00C6},
  {"ø", "Ø", 1.0, Copy, 0x00F8, 0, 0x00D8},
  {"", "", 0.0, EndRow},

  {"⇧", "⇫", 1.25, Mod, Shift, .scheme = 1},
  {"!", "!", 1.0, Copy, 0x0021, 0, 0x0021},
  {"z", "Z", 1.0, Code, KEY_Z},
  {"x", "X", 1.0, Code, KEY_X},
  {"c", "C", 1.0, Code, KEY_C},
  {"v", "V", 1.0, Code, KEY_V},
  {"b", "B", 1.0, Code, KEY_B},
  {"n", "N", 1.0, Code, KEY_N},
  {"m", "M", 1.0, Code, KEY_M},
  {"?", "?", 1.0, Copy, 0x003F, 0, 0x003F},
  {"⌫", "⌫", 1.25, Code, KEY_BACKSPACE, .scheme = 1},
  {"", "", 0.0, EndRow},

  {"123", "123", 1.5, Layout, 0, &layouts[Numbers], .scheme = 1},
  {"Esc", "Esc", 1.0, Code, KEY_ESC, .scheme = 1},
  {",", ",", 1.0, Copy, 0x002C, 0, 0x002C},
  {"", "Tab", 3.5, Code, KEY_SPACE},
  {".", ".", 1.0, Copy, 0x002E, 0, 0x002E},
  {"⏎", "⏎", 1.5, Code, KEY_ENTER, .scheme = 1},
  {"⌄", "⌄", 1.0, Hide, 0, .scheme = 1},

  /* end of layout */
  {"", "", 0.0, Last},
};

static struct key keys_numbers[] = {
  {"1", "1", 1.0, Code, KEY_1},
  {"2", "2", 1.0, Code, KEY_2},
  {"3", "3", 1.0, Code, KEY_3},
  {"4", "4", 1.0, Code, KEY_4},
  {"5", "5", 1.0, Code, KEY_5},
  {"6", "6", 1.0, Code, KEY_6},
  {"7", "7", 1.0, Code, KEY_7},
  {"8", "8", 1.0, Code, KEY_8},
  {"9", "9", 1.0, Code, KEY_9},
  {"0", "0", 1.0, Code, KEY_0},
  {"", "", 0.0, EndRow},

  {"-", "-", 1.0, Copy, 0x002D, 0, 0x002D},
  {"/", "/", 1.0, Copy, 0x002F, 0, 0x002F},
  {":", ":", 1.0, Copy, 0x003A, 0, 0x003A},
  {";", ";", 1.0, Copy, 0x003B, 0, 0x003B},
  {"(", "(", 1.0, Copy, 0x0028, 0, 0x0028},
  {")", ")", 1.0, Copy, 0x0029, 0, 0x0029},
  {"`", "`", 1.0, Copy, 0x0060, 0, 0x0060},
  {"&", "&", 1.0, Copy, 0x0026, 0, 0x0026},
  {"@", "@", 1.0, Copy, 0x0040, 0, 0x0040},
  {"\"", "\"", 1.0, Copy, 0x0022, 0, 0x0022},
  {"", "", 0.0, EndRow},

  {"#+=", "#+=", 2.0, Layout, 0, &layouts[Symbols], .scheme = 1},
  {".", ".", 1.2, Copy, 0x002E, 0, 0x002E},
  {",", ",", 1.2, Copy, 0x002C, 0, 0x002C},
  {"?", "?", 1.2, Copy, 0x003F, 0, 0x003F},
  {"!", "!", 1.2, Copy, 0x0021, 0, 0x0021},
  {"'", "'", 1.2, Copy, 0x0027, 0, 0x0027},
  {"⌫", "⌫", 2.0, Code, KEY_BACKSPACE, .scheme = 1},
  {"", "", 0.0, EndRow},

  {"ABC", "ABC", 2.0, Layout, 0, &layouts[Letters], .scheme = 1},
  {"Esc", "Esc", 1.0, Code, KEY_ESC, .scheme = 1},
  {"", "Tab", 4.0, Code, KEY_SPACE},
  {"⏎", "⏎", 2.0, Code, KEY_ENTER, .scheme = 1},
  {"⌄", "⌄", 1.0, Hide, 0, .scheme = 1},

  /* end of layout */
  {"", "", 0.0, Last},
};

static struct key keys_symbols[] = {
  {"[", "[", 1.0, Copy, 0x005B, 0, 0x005B},
  {"]", "]", 1.0, Copy, 0x005D, 0, 0x005D},
  {"{", "{", 1.0, Copy, 0x007B, 0, 0x007B},
  {"}", "}", 1.0, Copy, 0x007D, 0, 0x007D},
  {"#", "#", 1.0, Copy, 0x0023, 0, 0x0023},
  {"%", "%", 1.0, Copy, 0x0025, 0, 0x0025},
  {"^", "^", 1.0, Copy, 0x005E, 0, 0x005E},
  {"*", "*", 1.0, Copy, 0x002A, 0, 0x002A},
  {"+", "+", 1.0, Copy, 0x002B, 0, 0x002B},
  {"=", "=", 1.0, Copy, 0x003D, 0, 0x003D},
  {"", "", 0.0, EndRow},

  {"_", "_", 1.0, Copy, 0x005F, 0, 0x005F},
  {"\\", "\\", 1.0, Copy, 0x005C, 0, 0x005C},
  {"|", "|", 1.0, Copy, 0x007C, 0, 0x007C},
  {"~", "~", 1.0, Copy, 0x007E, 0, 0x007E},
  {"<", "<", 1.0, Copy, 0x003C, 0, 0x003C},
  {">", ">", 1.0, Copy, 0x003E, 0, 0x003E},
  {"€", "€", 1.0, Copy, 0x20AC, 0, 0x20AC},
  {"$", "$", 1.0, Copy, 0x0024, 0, 0x0024},
  {"£", "£", 1.0, Copy, 0x00A3, 0, 0x00A3},
  {"•", "•", 1.0, Copy, 0x2022, 0, 0x2022},
  {"", "", 0.0, EndRow},

  {"123", "123", 2.0, Layout, 0, &layouts[Numbers], .scheme = 1},
  {"←", "←", 1.5, Code, KEY_LEFT, .scheme = 1},
  {"↓", "↓", 1.5, Code, KEY_DOWN, .scheme = 1},
  {"↑", "↑", 1.5, Code, KEY_UP, .scheme = 1},
  {"→", "→", 1.5, Code, KEY_RIGHT, .scheme = 1},
  {"⌫", "⌫", 2.0, Code, KEY_BACKSPACE, .scheme = 1},
  {"", "", 0.0, EndRow},

  {"ABC", "ABC", 2.0, Layout, 0, &layouts[Letters], .scheme = 1},
  {"Esc", "Esc", 1.0, Code, KEY_ESC, .scheme = 1},
  {"", "Tab", 4.0, Code, KEY_SPACE},
  {"⏎", "⏎", 2.0, Code, KEY_ENTER, .scheme = 1},
  {"⌄", "⌄", 1.0, Hide, 0, .scheme = 1},

  /* end of layout */
  {"", "", 0.0, Last},
};

/* Fallback layout picker. Unreachable in normal use (there is no compose key
 * in this set), but keyboard.c references `Index` unconditionally.
 */
static struct key keys_index[] = {
  {"ABC", "ABC", 1.0, Layout, 0, &layouts[Letters], .scheme = 1},
  {"123", "123", 1.0, Layout, 0, &layouts[Numbers], .scheme = 1},
  {"#+=", "#+=", 1.0, Layout, 0, &layouts[Symbols], .scheme = 1},
  {"", "", 0.0, EndRow},

  /* end of layout */
  {"", "", 0.0, Last},
};
